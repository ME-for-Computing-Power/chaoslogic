from base_assistant import BaseAssistant
import os

class VerificationEngineerAssistant(BaseAssistant):
    def __init__(self, agent) -> None:
        super().__init__(agent)
        self.name = "Verification Engineer Wolf"
        # State wait_verification, verification_outdated
        self.state = "wait_verification"
        #define the path to prompt
        self.prompt_path = os.path.join('prompt', 'veri_engineer')
    
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
        
        user_requirements_exist, user_requirements_mtime, user_requirements = self.env.get_user_requirements()
        spec_exist, spec_mtime, spec = self.env.get_spec()
        #cmodel_code_exist, cmodel_code_mtime, cmodel_code = self.env.get_cmodel_code()
        design_code_exist, design_code_mtime, design_code = self.env.get_design_code()
        verification_report_exist, verification_report_mtime, verification_report = self.env.get_verification_report()

        if self.state == "wait_verification" or self.state == "review_testbench":
            assert(spec_exist)
            #assert(cmodel_code_exist)
            assert(design_code_exist)
            return self.load_prompt('create_tb.md')
        else:
            assert(spec_exist)
            #assert(cmodel_code_exist)
            assert(design_code_exist)
            assert(verification_report_exist)
            return self.load_prompt('update_tb.md')
    
    def submit_testbench(self, code):
        self.env.manual_log(self.name, "提交了验证 Testbench 代码")
        self.env.write_verification_code(code)
    
    def execute(self):
        self.clear_short_term_memory()
        self.env.delete_verification_binary()
        #self.call_llm("Observe and analyze the project situation, show me your observation and think", tools_enable=False)

        while True:
            if (self.state == "wait_verification" or self.state == "verification_outdated"):
                llm_message = self.call_llm("""
                    提交你的 Testbench。
                    Testbench 中应利用 assertion 检查设计是否正确。
                    提交后，Testbench将会编译并运行。
                    """)
            elif(self.state == "review_testbench"):
                llm_message = self.call_llm(f"""
                Testbench 编译、运行结果如下：
                ```
                {self.env.compile_and_run_verification()}
                ```
                若 Testbench 本身存在问题，使用 submit_testbench 提交修改后的Testbench。

                当确认Testbench 本身不存在问题后，若 Testbench 检查出了设计中的错误，则该错误应当写入测试报告中，使用 write_verification_report 提交测试报告。
                """)
            if llm_message["tool_call"]:
                name = llm_message["tool_call"]["tool_name"]
                args = llm_message["tool_call"]["parameters"]
                if name == "submit_testbench":
                    self.submit_testbench(args["code"])
                    #self.reflect_tool_call(name, output)
                    self.state = "review_testbench"
                elif name == "write_verification_report":
                    self.env.write_verification_report(args["report"])
                    #self.reflect_tool_call(name, "success")
                    self.state = "verification_outdated"
                    return
                

