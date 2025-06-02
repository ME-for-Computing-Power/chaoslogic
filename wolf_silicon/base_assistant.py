import json
import re

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
    
    def decode_tool_call(self, tool_call):
        return tool_call.id, tool_call.function.name, json.loads(tool_call.function.arguments)
    
    def reflect_tool_call(self, id, result):
        self.update_short_term_memory({
            "role":"tool",
            "tool_call_id":id,
            "content":result
        })
        messages = [
            {
                "role": "system",
                "content": self.get_system_prompt()
            },
            {
                "role": "user",
                "content": self.get_long_term_memory()
            },
            *self.get_short_term_memory()
        ]
        completion = self.agent.model_client.chat.completions.create(
            model=self.agent.MODEL_NAME,
            messages=messages,
            tools=self.get_tools_description(),
            tool_choice="none"
        )
        self.update_short_term_memory(completion.choices[0].message)
        self.env.auto_message_log(self.name, completion.choices[0].message)


    def call_llm(self, user_message,tools_enabled=False):
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
                "role": "user",
                "content": self.get_long_term_memory()
            },
            *self.get_short_term_memory()
        ]
        self.env.manual_log(self.name, f"Messages: {messages}")
        response = self.agent.model_client.chat.completions.create(
            model=self.agent.MODEL_NAME,
            messages=messages,
            max_tokens=self.agent.MAX_TOKENS,
            stream=True,
            tools=self.get_tools_description(),
            tool_choice="required" if tools_enabled else "none"
        )
        status = 0
        message = ""
        func_call_list = []
        for chunk in response:
            for choice in chunk.choices:
                if hasattr(choice.delta, "tool_calls"):
                    for tcchunk in choice.delta.tool_calls:
                        if len(func_call_list) <= tcchunk.index:
                            func_call_list.append({
                                "id": "",
                                "name": "",
                                "type": "function", 
                                "function": { "name": "", "arguments": "" } 
                            })
                        tool_status = 0
                        tc = func_call_list[tcchunk.index]
                        if tcchunk.id:
                            tc["id"] += tcchunk.id
                        if tcchunk.function.name:
                            tc["function"]["name"] += tcchunk.function.name
                        if tcchunk.function.arguments:
                            if tool_status == 0:
                                tool_status = 1
                                self.env.manual_log(self.name, f"工具名称：{tcchunk.function.name}")
                            tc["function"]["arguments"] += tcchunk.function.arguments 
                            self.env.manual_log(self.name, tcchunk.function.arguments, False)
                if hasattr(choice.delta, "reasoning_content"):
                    if (choice.delta.reasoning_content):
                        if status != 1:
                            status = 1
                            self.env.manual_log(self.name, "思考：")
                        self.env.manual_log(self.name, choice.delta.reasoning_content, False)
                if hasattr(choice.delta, "content"):
                    if (choice.delta.content):
                        if status != 2:
                            status = 2
                            self.env.manual_log(self.name, "输出：")
                        self.env.manual_log(self.name, choice.delta.content, False)
                        message += choice.delta.content 
        self.update_short_term_memory(message)
        #self.env.auto_message_log(self.name, completion.choices[0].message)
        return message, func_call_list
