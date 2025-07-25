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
        # print("Loading prompt from ", prompt_path)
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

    def get_tools_description(self):
        tools = []
        submit_spec = {
            "type": "function",
            "function": {
                "name": "submit_spec",
                "description": "提交SPEC文档。",
                "strict": True,
                "parameters": {
                    "type": "object",
                    "properties": {
                        "spec": {"type": "string", "description": "SPEC文档内容"},
                        "overwrite": {"type": "boolean", "description": "true表示覆盖现有的SPEC，false表示将其追加到现有SPEC中"}
                    },
                    "required": ["spec", "overwrite"],
                    "additionalProperties": False
                }
            }
        }
        accept_report = {
            "type": "function",
            "function": {
                "name": "accept_report",
                "description": "批准当前报告。",
                "strict": True
            }
        }
        if self.state == "wait_spec":
            tools.append(submit_spec)
        elif self.state == "review_verification_report":
            tools.append(accept_report)
            tools.append(submit_spec)
        else:
            tools.append(submit_spec)
        return tools

#FSM-like
    def execute(self) -> str:
        self.clear_short_term_memory()
        #self.call_llm("分析项目情况，给出你的观察和想法", tools_enable=False)
        while True:
            if self.state == "wait_spec":
                llm_message, func_call_list = self.call_llm("使用工具提交Spec", tools_enable=True)
                for tool_call in func_call_list:
                    tool_id, name, args = self.decode_tool_call(tool_call)
                    if name == "submit_spec":
                        self.env.write_spec(args["spec"], args["overwrite"])
                        self.env.manual_log(self.name, "提交了设计规格文档")
                        self.reflect_tool_call(tool_id, "success")
                        self.state = "review_verification_report"
                        return "design"
                    else:
                        raise Exception("未知的Function Call")
            elif self.state == "review_verification_report":
                llm_message, func_call_list = self.call_llm("审阅验证报告", tools_enable=True)
                for tool_call in func_call_list:
                    tool_id, name, args = self.decode_tool_call(tool_call)
                    if name == "accept_report":
                        self.state = "accept_report"
                        return "user"
                    elif name == "submit_spec":
                        self.env.write_spec(args["spec"], args["overwrite"])
                        self.env.manual_log(self.name, "更新了设计规格文档")
                        self.state = "review_verification_report"
                        self.reflect_tool_call(tool_id, "success")
                        return "design" 




