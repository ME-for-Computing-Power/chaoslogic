from base_assistant import BaseAssistant
import os

class DesignEngineerAssistant(BaseAssistant):
    def __init__(self, agent) -> None:
        super().__init__(agent)
        self.name = "设计工程师"
        # State wait_design, design_finished
        self.state = "wait_design"
        self.max_short_term_memory_len = 10
        self.is_lint_clean = False
        #define the path to prompt
        self.prompt_path = os.path.join('prompt', 'design_engineer')
    
    def load_prompt(self, filename) -> str:
        prompt_path = os.path.join(self.prompt_path,filename)
        # print("Loading prompt from ", prompt_path)
        with open(prompt_path, 'r', encoding='utf-8') as f:
            md_content = f.read()
            
        user_requirements_exist, user_requirements_mtime, user_requirements = self.env.get_user_requirements()
        spec_exist, spec_mtime, spec = self.env.get_spec()
        #cmodel_code_exist, cmodel_code_mtime, cmodel_code = self.env.get_cmodel_code()

        md_content = md_content.replace('{user_requirements}', user_requirements)
        md_content = md_content.replace('{spec}', spec)
        
        if '{rtl_code}' in md_content:
            code_exist, code_mtime, rtl_code = self.env.get_design_code()
            if code_exist:
                md_content = md_content.replace('{rtl_code}',rtl_code)
            else:
                raise ValueError("Design code not found in ", self.env._design_path)
            
        if '{feedback}' in md_content:
            feedback_exist, feedback_mtime, feedback = self.env.get_feedback()
            if feedback_exist:
                md_content = md_content.replace('{feedback}', feedback)
            else:
                raise ValueError("Feedback not found in environment")
        return md_content

    def get_system_prompt(self):
        return self.load_prompt('system_prompt.md')
        
    def get_long_term_memory(self):

        if self.state == "wait_design":
            return self.load_prompt('create_design.md')
        
        if self.state == "design_error":#该状态不可在本类型中进入，仅能在agent.py中控制
            return self.load_prompt('update_design.md')
    
    def submit_design(self, code):
        self.env.manual_log(self.name, "提交了 IP 设计代码")
        self.env.write_design_code(code)
        self.env.manual_log(self.name, "开始语法检查")
        lint_output = self.env.lint_design()
        self.env.manual_log(self.name, lint_output)
        lint_output_lowwer = lint_output.lower()
        self.is_lint_clean = "error" not in lint_output_lowwer and "warning" not in lint_output_lowwer
        if self.is_lint_clean:
            return "语法检测已通过"
        else:
            return f"语法验证未通过，报错： {lint_output}"
    
    def design_code_exist(self) -> bool:
        design_code_exist, design_code_mtime, _ = self.env.get_design_code()
        return design_code_exist
    
    def get_tools_description(self):
        
        submit_design = {
            "type": "function",
            "function": {
                "name": "submit_design",
                "description": "提交你的 Verilog 设计代码。设计代码将保存在一个 .v 文件中。你的设计代码在提交后会自动进行语法检查。",
                "strict": True,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "code": {"type": "string", "description": "Verilog设计代码"}
                    },
                    "required": ["code"],
                    "additionalProperties": False
                }
            }
        }
        # handover_to_verification = {
        #     "type": "function",
        #     "function": {
        #         "name": "handover_to_verification",
        #         "description": "将设计交接给验证工程师进行后续验证。",
        #         "strict": True
        #     }
        # }

        # if self.ready_to_handover():
        #     return [submit_design, handover_to_verification]
        # else:
        #     return [submit_design]
        return [submit_design]
    
    def execute(self):
        self.clear_short_term_memory()
        #self.call_llm("Observe and analyze the project situation, show me your observation and think", tools_enable=False)
        self.is_lint_clean = False
        lint_output = ""
        while True:
            if not self.design_code_exist():
                llm_message, func_call_list = self.call_llm("""
使用`submit_design`提交你的设计。
                        
设计仅在一个.v文件中存储，且符合verilog-2000标准。
设计的结果将送往语法检查。当没有语法错误时，设计即会通过。               
                    """, tools_enable=True)
            elif self.state == "design_error":

                    llm_message, func_call_list = self.call_llm('按照反馈修改代码', tools_enable=True)
                    self.state = "design_finished"
            elif not self.is_lint_clean:
                llm_message, func_call_list = self.call_llm(f"""
刚才的代码中存在语法错误：
```
{lint_output}
```
修改错误，并用 submit_design 重新提交。
                    """, tools_enable=True)
            else:
                self.state = "design_finished"
                return 0
            
            # if toolcall list is empty, raise an error
            if not func_call_list:
                raise ValueError("大模型未调用任何工具，请检查大模型的输出。")
            for tool_call in func_call_list:
                tool_id, name, args = self.decode_tool_call(tool_call)
                if name == "submit_design":
                    lint_output = self.submit_design(args["code"])
                    self.reflect_tool_call(tool_id, "success")
                

