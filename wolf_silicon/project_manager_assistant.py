from base_assistant import BaseAssistant
import os

class ProjectManagerAssistant(BaseAssistant):
    def __init__(self, agent) -> None:
        super().__init__(agent)
        self.name = "项目经理"
        #State: wait_spec, review_verification_report, new_user_requirements.
        self.state = "wait_spec"
        #define the path to prompt
        self.prompt_path = os.path.join('prompt', 'proj_manager')
    
    def load_prompt(self, filename) -> str:
        prompt_path = os.path.join(self.prompt_path,filename)
        print("Loading prompt from ", prompt_path)
        with open(prompt_path, 'r', encoding='utf-8') as f:
            md_content = f.read()
            
        user_requirements_exist, user_requirements_mtime, user_requirements = self.env.get_user_requirements()
        spec_exist, spec_mtime, spec = self.env.get_spec()
        verification_report_exist, verification_report_mtime, verification_report = self.env.get_verification_report()

        md_content = md_content.replace('{user_requirements}', user_requirements)
        md_content = md_content.replace('{spec}', spec)
        md_content = md_content.replace('{verification_report}', verification_report)

        return md_content

    def get_system_prompt(self) -> str:
        # return """You are the Project Manager of Wolf-Silicon Hardware IP Design Team, 
        # please help user to finish the project. 
        # Use tools when avaliable. 
        # """
        return self.load_prompt('system_prompt.md')
    
    def get_long_term_memory(self) -> str:
        user_requirements_exist, user_requirements_mtime, user_requirements = self.env.get_user_requirements()
        spec_exist, spec_mtime, spec = self.env.get_spec()
        verification_report_exist, verification_report_mtime, verification_report = self.env.get_verification_report()

        if self.state == "wait_spec":
            assert (user_requirements_exist)
            return self.load_prompt('create_spec.md')
        elif self.state == "review_verification_report":
            assert (user_requirements_exist)
            assert (spec_exist)
            assert (verification_report_exist)
            return self.load_prompt('review_veri.md')
        else:
            assert (user_requirements_exist)
            assert (spec_exist)
            assert (verification_report_exist)
            return self.load_prompt('update_spec.md')

#FSM-like
    def execute(self) -> str:
        self.clear_short_term_memory()
        #self.call_llm("分析项目情况，给出你的观察和想法", tools_enable=False)
        while True:
            if self.state == "wait_spec" or self.state == "new_user_requirements":
                llm_message = self.call_llm("使用外部工具提交Spec")
                if llm_message["tool_call"]:
                    name = llm_message["tool_call"]["tool_name"]
                    args = llm_message["tool_call"]["parameters"]
                    if name == "submit_spec":
                        self.env.write_spec(args["spec"], args["overwrite"])
                        self.env.manual_log(self.name, "提交了设计规格文档")
                        #self.reflect_tool_call(name, "success")
                        self.state = "review_verification_report"
                        return "design"
                    else:
                        raise Exception("未知的Function Call")
            elif self.state == "review_verification_report":
                llm_message = self.call_llm("审阅验证报告，并调用合适的工具")
                if llm_message["tool_call"]:
                    name = llm_message["tool_call"]["tool_name"]
                    args = llm_message["tool_call"]["parameters"]
                    if name == "accept_report":
                        #self.state = "new_user_requirements"
                        return "user"
                    elif name == "submit_spec":
                        self.env.write_spec(args["spec"], args["overwrite"])
                        self.env.manual_log(self.name, "更新了设计规格文档")
                        self.state = "review_verification_report"
                        #self.reflect_tool_call(name, "success")
                        return "design" 




