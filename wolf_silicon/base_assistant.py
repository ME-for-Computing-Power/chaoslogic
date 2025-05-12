import json

class BaseAssistant(object):

    def __init__(self, agent) -> None:
        self.env = agent.env
        self.name = "BaseAssistant"
        self.agent = agent
        self.short_term_memory = []
        self.max_short_term_memory_len = self.agent.MAX_SHORT_TERM_MEMORY

    def update_short_term_memory(self, msg: object):
        self.short_term_memory.append(msg)
        if len(self.short_term_memory) > self.max_short_term_memory_len:
            self.short_term_memory.pop(0)
        while self.short_term_memory and self.short_term_memory[0]["role"] == "assistant":
            self.short_term_memory.pop(0)

    def clear_short_term_memory(self):
        self.short_term_memory.clear()

    def get_short_term_memory(self):
        return self.short_term_memory

    def get_long_term_memory(self):
        raise NotImplementedError(
            "get_long_term_memory() method must be implemented by subclass.")

    def get_tools_description(self):
        raise NotImplementedError(
            "get_tools_description() method must be implemented by subclass.")

    def get_system_prompt(self):
        raise NotImplementedError(
            "get_system_prompt() method must be implemented by subclass.")
    
    # def decode_tool_call(self, tool_call):
    #     return tool_call.id, tool_call.function.name, json.loads(tool_call.function.arguments)
    
    def reflect_tool_call(self, name, result):
        self.update_short_term_memory({
            "role": "user",
            "content": f"RESPONSE:{result}\n"
        })
        messages = [
            {
                "role": "system",
                "content": self.get_system_prompt()
            },
            {
                "role": "system",
                "content": self.get_long_term_memory()
            },
            *self.get_short_term_memory()
        ]
        self.env.manual_log(self.name, f"Messages: {messages}")
        response = self.agent.model_client.chat.completions.create(
            model=self.agent.MODEL_NAME,
            messages=messages,
            max_tokens=self.agent.MAX_TOKENS,
            stream=True
        )
        status = 0
        message = ""
        for chunk in response:
            for choice in chunk.choices:
                # 先打印 reasoning_content
                if hasattr(choice.delta, "reasoning_content"): 
                    if(choice.delta.reasoning_content):
                        if status != 1:
                            status = 1
                            self.env.manual_log(self.name, "思考：")
                        self.env.manual_log(self.name, choice.delta.reasoning_content, False)
                if hasattr(choice.delta, "content"):
                    if(choice.delta.content):
                        if status != 2:
                            status = 2
                            self.env.manual_log(self.name, "输出：")
                        self.env.manual_log(self.name, choice.delta.content, False)
                        message += choice.delta.content
                
        self.update_short_term_memory({   
            "role": "assistant",
            "content": message
        })

    def process_message(self, message):
        #判断message的第一行
        ret = {}
        if message.startswith("TYPE: ANSWER"):
            ret["content"] = "\n".join(message.split("\n")[1:])
        elif message.startswith("TYPE: MCP"):
            code = self.process_code("\n".join(message.split("\n")[1:]))
            tool_call = json.loads(code)
            ret["tool_call"] = tool_call
        else:
            raise ValueError("Invalid message format")
        
        return ret

    def process_code(self, code):
        return code.replace("```json", "").replace("```", "")
    
    def call_llm(self, user_message):
        self.env.manual_log(self.name, f"Message: {user_message}")
        self.update_short_term_memory({
            "role": "user",
            "content": user_message
        })
        messages = [
            {
                "role": "system",
                "content": self.get_system_prompt()
            },
            {
                "role": "system",
                "content": self.get_long_term_memory()
            },
            *self.get_short_term_memory()
        ]
        self.env.manual_log(self.name, f"Messages: {messages}")
        response = self.agent.model_client.chat.completions.create(
            model=self.agent.MODEL_NAME,
            messages=messages,
            max_tokens=self.agent.MAX_TOKENS,
            stream=True
        )
        status = 0
        message = ""
        for chunk in response:
            for choice in chunk.choices:
                # 先打印 reasoning_content
                if hasattr(choice.delta, "reasoning_content"): 
                    if(choice.delta.reasoning_content):
                        if status != 1:
                            status = 1
                            self.env.manual_log(self.name, "思考：")
                        self.env.manual_log(self.name, choice.delta.reasoning_content, False)
                if hasattr(choice.delta, "content"):
                    if(choice.delta.content):
                        if status != 2:
                            status = 2
                            self.env.manual_log(self.name, "输出：")
                        self.env.manual_log(self.name, choice.delta.content, False)
                        message += choice.delta.content
                
        self.update_short_term_memory({   
            "role": "assistant",
            "content": message
        })
        
        #self.env.auto_message_log(self.name, completion.choices[0].message)
        return self.process_message(message)
