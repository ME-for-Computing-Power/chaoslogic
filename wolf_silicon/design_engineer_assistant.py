from base_assistant import BaseAssistant
import os

class DesignEngineerAssistant(BaseAssistant):
    def __init__(self, agent) -> None:
        super().__init__(agent)
        self.name = "Design Engineer Wolf"
        # State wait_design, design_outdated
        self.state = "wait_design"
        self.max_short_term_memory_len = 10
        self.is_lint_clean = False
        #define the path to prompt
        self.prompt_path = os.path.join('prompt', 'design_engineer')
    
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
        cmodel_code_exist, cmodel_code_mtime, _ = self.env.get_cmodel_code()
        design_code_exist, design_code_mtime, _ = self.env.get_design_code()
        return design_code_exist and design_code_mtime > cmodel_code_mtime
    
    def get_tools_description(self):
        
        submit_design = {
            "type": "function",
            "function": {
                "name": "submit_design",
                "description": "Submit Your Verilog Design Code. The Design Code Saved in a single .v file. Your Design Code will be lint automatically after submission.",
                "strict": True,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "code": {"type": "string", "description": "Design Verilog Code"}
                    },
                    "required": ["code"],
                    "additionalProperties": False
                }
            }
        }
        handover_to_verification = {
            "type": "function",
            "function": {
                "name": "handover_to_verification",
                "description": "Handover the Design to the Verification Engineer Wolf for further verification.",
                "strict": True
            }
        }

        if self.ready_to_handover():
            return [submit_design, handover_to_verification]
        else:
            return [submit_design]
    
    def execute(self):
        self.clear_short_term_memory()
        self.call_llm("Observe and analyze the project situation, show me your observation and think", tools_enable=False)
        self.is_lint_clean = False
        while True:
            if not self.ready_to_handover():
                llm_message = self.call_llm("""
                    Please submit your Design code.

                    All Design code is assumed to be in a single .v file.
                    Your Design code should be synthesizable and obey the verilog-2001 standard.
                    Your Design code should be lint clean.
                    Your Design code will be automatically lint after submission, Please Note the Result.

                    """, tools_enable=True)
            elif not self.is_lint_clean:
                llm_message = self.call_llm(f"""
                Your recently submitted code is not lint clean, the lint result
                ```
                {self.env.lint_design()}
                ```
                Please resubmit the Design code Use 【submit_design】

                """, tools_enable=True)
            else:
                llm_message = self.call_llm(f"""
                Your recently submitted code is ready. Please decide whether to:

                handover the Design to the Verification Engineer Wolf Use 【handover_to_verification】

                """, tools_enable=True) 
            for tool_call in llm_message.tool_calls:
                tool_id, name, args = self.decode_tool_call(tool_call)
                if name == "submit_design":
                    lint_output = self.submit_design(args["code"])
                    self.reflect_tool_call(tool_id, lint_output)
                elif name == "handover_to_verification":
                    self.state = "design_outdated"
                    return
                

