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
        with open(os.path.join(self.prompt_path,filename), 'r', encoding='utf-8') as f:
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

        if self.state == "wait_verification":
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
        compile_run_output = self.env.compile_and_run_verification()
        return compile_run_output
    
    def get_tools_description(self):
        
        submit_testbench = {
            "type": "function",
            "function": {
                "name": "submit_testbench",
                "description": "Submit Your Testbench Code. The Testbench Saved in a tb.v file. Your testbench code will compile and run automatically, please note the result.",
                "strict": True,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "code": {"type": "string", "description": "Testbench Code"}
                    },
                    "required": ["code"],
                    "additionalProperties": False
                }
            }
        }
        write_verification_report = {
            "type": "function",
            "function": {
                "name": "write_verification_report",
                "description": "Write down your verification report",
                "strict": True,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "report": {"type": "string", "description": "Verification Report"}
                    },
                    "required": ["report"],
                    "additionalProperties": False
                }
            }
        }

        if self.env.is_verification_binary_exist():
            return [submit_testbench, write_verification_report]
        else:
            return [submit_testbench]
    
    def execute(self):
        self.clear_short_term_memory()
        self.env.delete_verification_binary()
        self.call_llm("Observe and analyze the project situation, show me your observation and think", tools_enable=False)

        while True:
            if (not self.env.is_verification_binary_exist()):
                llm_message = self.call_llm("""
                    Please submit your Testbench code.

                    All Testbench code is assumed to be in a single tb.v file, and the top module is named tb.
                    Your Testbench code should use assertion to check the correctness of the design.
                    Your Testbench code will be automatically compile and run after submission, Please Note the Result.

                    """, tools_enable=True)
            else:
                llm_message = self.call_llm(f"""
                There is a Testbench binary and the execution result
                ```
                {self.env.run_verification()}
                ```
                
                Your duty is to create correct testbench code rather than to debug the design.

                No matter the correctness of the design, you should write a verification report.

                Please decide whether to:
                
                Write down your verification report - Use【write_verification_report】
                
                OR

                Resubmit the testbench code - Use【submit_testbench】

                """, tools_enable=True)
            for tool_call in llm_message.tool_calls:
                tool_id, name, args = self.decode_tool_call(tool_call)
                if name == "submit_testbench":
                    output = self.submit_testbench(args["code"])
                    self.reflect_tool_call(tool_id, output)
                elif name == "write_verification_report":
                    self.env.write_verification_report(args["report"])
                    self.reflect_tool_call(tool_id, "success")
                    self.state = "verification_outdated"
                    return
                

