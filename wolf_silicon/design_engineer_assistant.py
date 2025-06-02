from base_assistant import BaseAssistant
import os

class DesignEngineerAssistant(BaseAssistant):
    def __init__(self, agent) -> None:
        super().__init__(agent)
        self.name = "设计工程师"
        # State wait_design, design_outdated
        self.state = "wait_design"
        self.max_short_term_memory_len = 10
        self.is_lint_clean = False
        #define the path to prompt
        self.prompt_path = os.path.join('prompt', 'design_engineer')
    
    def load_prompt(self, filename) -> str:
        prompt_path = os.path.join(self.prompt_path,filename)
        print("Loading prompt from ", prompt_path)
        with open(prompt_path, 'r', encoding='utf-8') as f:
            md_content = f.read()
            
        user_requirements_exist, user_requirements_mtime, user_requirements = self.env.get_user_requirements()
        spec_exist, spec_mtime, spec = self.env.get_spec()
        #cmodel_code_exist, cmodel_code_mtime, cmodel_code = self.env.get_cmodel_code()

        md_content = md_content.replace('{user_requirements}', user_requirements)
        md_content = md_content.replace('{spec}', spec)
        #md_content = md_content.replace('{cmodel_code}', cmodel_code)
        return md_content

    def get_system_prompt(self):
        return self.load_prompt('system_prompt.md')
        
    def get_long_term_memory(self):
        
        spec_exist, spec_mtime, spec = self.env.get_spec()
        user_requirements_exist, user_requirements_mtime, user_requirements = self.env.get_user_requirements()
        #cmodel_code_exist, cmodel_code_mtime, cmodel_code = self.env.get_cmodel_code()
        design_code_exist, design_code_mtime, design_code = self.env.get_design_code()
        verification_report_exist, verification_report_mtime, verification_report = self.env.get_verification_report()

        if self.state == "wait_design":
            assert(spec_exist)
            #assert(cmodel_code_exist)
            return self.load_prompt('create_design.md')
        else:
            assert(spec_exist)
            #assert(cmodel_code_exist)
            assert(design_code_exist)
            assert(verification_report_exist)
            return self.load_prompt('update_design.md')
    
    def submit_design(self, code):
        self.env.manual_log(self.name, "提交了 IP 设计代码")
        self.env.write_design_code(code)
        lint_output = self.env.lint_design()
        lint_output_lowwer = lint_output.lower()
        self.is_lint_clean = "error" not in lint_output_lowwer and "warning" not in lint_output_lowwer
        if self.is_lint_clean:
            return "Your code submitted successfully, and the lint result is clean."
        else:
            return f"Your code lint failed, please check the lint result: {lint_output}"
    
    def ready_to_handover(self) -> bool:
        design_code_exist, design_code_mtime, _ = self.env.get_design_code()
        return design_code_exist
    
    
    def execute(self):
        self.clear_short_term_memory()
        #self.call_llm("Observe and analyze the project situation, show me your observation and think", tools_enable=False)
        self.is_lint_clean = False
        while True:
            if not self.ready_to_handover():
                llm_message = self.call_llm("""
                    使用MCP提交你的设计。
                                            
                    设计应当仅在一个.v文件中存储，且符合verilog-2000标准。
                    设计的结果将送往语法检查。当没有语法错误时，设计即会通过               
                    """)
            elif not self.is_lint_clean:
                llm_message = self.call_llm(f"""
                    刚才的代码中存在语法错误：
                    ```
                    {self.env.lint_design()}
                    ```
                    修改错误，并用 submit_design 重新提交。

                    """)
            else:
                llm_message = self.call_llm(f"""
                    刚才的代码中没有语法错误。
                                                
                    若仍要修改，则使用 submit_design 重新提交。
                    若确认无误，则使用 handover_to_verification提交验证部门。
                    """) 
            if llm_message["tool_call"]:
                name = llm_message["tool_call"]["tool_name"]
                args = llm_message["tool_call"]["parameters"]
                if name == "submit_design":
                    lint_output = self.submit_design(args["code"])
                    self.reflect_tool_call(name, lint_output)
                elif name == "handover_to_verification":
                    self.state = "design_outdated"
                    return
                

