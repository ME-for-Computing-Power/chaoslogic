from base_assistant import BaseAssistant
import os

class VerificationEngineerAssistant(BaseAssistant):
    def __init__(self, agent) -> None:
        super().__init__(agent)
        self.name = "验证工程师"
        # State wait_verification, verification_finished
        self.state = "wait_verification"
        #define the path to prompt
        self.prompt_path = os.path.join('prompt', 'veri_engineer')
    
    def load_prompt(self, filename) -> str:
        prompt_path = os.path.join(self.prompt_path,filename)
        # print("Loading prompt from ", prompt_path)
        with open(prompt_path, 'r', encoding='utf-8') as f:
            md_content = f.read()
            
        user_requirements_exist, user_requirements_mtime, user_requirements = self.env.get_user_requirements()
        spec_exist, spec_mtime, spec = self.env.get_spec()
        veri_plan_exist, veri_plan_mtime, veri_plan = self.env.get_veri_plan()
        veri_code_exist, veri_code_mtime, veri_code = self.env.get_verification_code()
        #cmodel_code_exist, cmodel_code_mtime, cmodel_code = self.env.get_cmodel_code()

        md_content = md_content.replace('{user_requirements}', user_requirements)
        md_content = md_content.replace('{spec}', spec)
        md_content = md_content.replace('{veri_plan}', veri_plan)
        md_content = md_content.replace('{veri_code}', veri_code)
        #md_content = md_content.replace('{cmodel_code}', cmodel_code)

        return md_content
    
    def get_system_prompt(self):
        return self.load_prompt('system_prompt.md')
        
    def get_long_term_memory(self):
        
        user_requirements_exist, user_requirements_mtime, user_requirements = self.env.get_user_requirements()
        spec_exist, spec_mtime, spec = self.env.get_spec()
        #cmodel_code_exist, cmodel_code_mtime, cmodel_code = self.env.get_cmodel_code()
        design_code_exist, design_code_mtime, design_code = self.env.get_design_code()
        verification_report_exist, verification_report_mtime, verification_report = self.env.get_verification_report()

        if self.state == "wait_verification" or self.state == "review_testbench_1":
            return self.load_prompt('create_tb.md')
        else:
            if self.state == "error_in_design":
                return self.load_prompt('design_updated.md')
            return self.load_prompt('update_tb.md')
    
    def submit_testbench(self, code):
        self.env.manual_log(self.name, "提交了验证 Testbench 代码")
        # 删除所有包含 `timescale 的行
        cleaned_code = "\n".join(
            line for line in code.splitlines() if "`timescale" not in line
        )
        self.env.write_verification_code(cleaned_code)
        #compile_run_output = self.env.compile_and_run_verification()
        #return compile_run_output

    def submit_feedback(self, text):
        self.env.manual_log(self.name, "验证发现错误，向设计工程师提出反馈")
        self.env.write_feedback(text)

    def get_tools_description(self):
        
        submit_testbench = {
            "type": "function",
            "function": {
                "name": "submit_testbench",
                "description": "提交你的 Testbench 代码。Testbench 将保存在一个 tb.v 文件中",
                "strict": True,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "code": {"type": "string", "description": "Testbench代码"}
                    },
                    "required": ["code"],
                    "additionalProperties": False
                }
            }
        }
        write_feedback = {#验证反馈，反馈给设计师
            "type": "function",
            "function": {
                "name": "write_feedback",
                "description": "撰写验证反馈。",
                "strict": True,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "text": {"type": "string", "description": "验证反馈"}
                    },
                    "required": ["text"],
                    "additionalProperties": False
                }
            }
        }
        write_verification_report = {
            "type": "function",
            "function": {
                "name": "write_verification_report",
                "description": "撰写验证报告。",
                "strict": True,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "report": {"type": "string", "description": "验证报告"}
                    },
                    "required": ["report"],
                    "additionalProperties": False
                }
            }
        }
        if self.state == "error_in_design":
            return [write_feedback, write_verification_report]
        else:
            return [submit_testbench, write_feedback, write_verification_report]
    
    def execute(self):
        self.clear_short_term_memory()
        self.env.delete_verification_binary()
        #self.call_llm("Observe and analyze the project situation, show me your observation and think", tools_enable=False)

        while True:
            if (self.state == "wait_verification" or self.state == "verification_finished"):
                llm_message, func_call_list = self.call_llm("""使用工具提交 Testbench。Testbench module 的名字固定为 `tb`，毋需设置`timescale`，因其在编译时将自动给出。Testbench 中应利用 assertion 检查设计是否正确。采用生成随机数的方式，避免对激励信号直接赋值。提交后，Testbench将会编译并运行，仿真时间限制为999999时间单位。
                    """, tools_enable=True)
            else:
                compile_output = self.env.compile_and_check_verification()
                if self.state == 'error_in_design':
                    sim_log = self.env.run_verification()

                    # if sim_log 超过200行，则截取前200行
                    lines = sim_log.splitlines()
                    if (len(lines) > 200):
                        sim_log = "\n".join(lines[0:200]) + "\n... (后略)"
                
                    # call llm to get feedback
                    llm_message, func_call_list = self.call_llm(f"""
设计工程师已按照你的反馈修改了设计代码，仿真结果如下
```
{sim_log}
```
若 Testbench 检查出了设计中的错误，则应用 write_feedback 将错误反馈给设计工程师。若确认测试正确无误，则使用 write_verification_report 提交验证报告
""", tools_enable=True)
                    
                elif  compile_output!= 'Success':#编译报错
                    llm_message, func_call_list = self.call_llm(f"""
Testbench 编译报错如下：
```
{compile_output}
```
使用 submit_testbench 提交修改后的Testbench。
""", tools_enable=True)
                else: #编译通过
                    sim_log = self.env.run_verification()
                    llm_message, func_call_list = self.call_llm(f"""
Testbench 成功编译，仿真结果如下：
```
{sim_log}
```
当确认Testbench 本身不存在问题后，若 Testbench 检查出了设计中的错误，则应用 write_feedback 将错误反馈给设计工程师。若确认测试正确无误，则使用 write_verification_report 提交验证报告。若Testbench有问题，则可使用 submit_testbench 提交修改后的Testbench。

""", tools_enable=True)
            # if toolcall list is empty, raise an error
            if not func_call_list:
                raise ValueError("大模型未调用任何工具，请检查大模型的输出。")
            for tool_call in func_call_list:
                tool_id, name, args = self.decode_tool_call(tool_call)
                if name == "submit_testbench":
                    self.submit_testbench(args["code"])
                    self.reflect_tool_call(tool_id, "success")
                    if self.state == "wait_verification":
                        self.state = "review_testbench_1"
                    elif self.state == "verification_finished":
                        self.state = "review_testbench_2"

                if name == 'write_feedback':
                    self.submit_feedback(args["text"])
                    self.reflect_tool_call(tool_id, "success")
                    self.state = "error_in_design"
                    return 'Error in Design'

                if name == "write_verification_report":
                    self.env.write_verification_report(args["report"])
                    self.reflect_tool_call(tool_id, "success")
                    self.state = "verification_finished"
                    return 0


