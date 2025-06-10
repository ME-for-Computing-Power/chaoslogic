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
        while self.short_term_memory and self.short_term_memory[0]["role"] != "user":
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
        arguments = tool_call["function"]["arguments"]
        protected = arguments.replace('\\n', '<<<TMP_NEWLINE>>>')
        filtered = protected.replace('\r', '').replace('\n', '')
        filtered_arguments = filtered.replace('<<<TMP_NEWLINE>>>', '\\n')
        return tool_call["id"], tool_call["function"]["name"], json.loads(filtered_arguments)
    
    def reflect_tool_call(self, id, result):
        self.update_short_term_memory({
            "role":"tool",
            "tool_call_id":id,
            "content":result
        })
        """messages = [
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
            tool_choice = "none"
        )
        message, func_call_list= self.handle_chat_response(response) 
        self.update_short_term_memory({
            "role": "assistant",
            "content": message
        })"""


    def call_llm(self, user_message,tools_enable=False):
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
        ##将 message 中的 \n 替换为真的换行符，改善log的可读性
        message_for_logging = json.dumps(messages, ensure_ascii=False).replace('\\n', '\n')
        self.env.manual_log(self.name, f"Messages: {message_for_logging}")
        response = self.agent.model_client.chat.completions.create(
            model=self.agent.MODEL_NAME,
            messages=messages,
            max_tokens=self.agent.MAX_TOKENS,
            stream=True,
            tools=self.get_tools_description(),
            tool_choice = "required" if tools_enable else "none"
        )

        message, func_call_list = self.handle_chat_response(response) 
        
        error_counter = 0
        while error_counter < self.agent.MAX_RETRY - 1:
            #检查json格式是否被破坏
            try:
                json.loads(message)
                for func_call in func_call_list:
                    #检查函数调用的参数是否是合法的json
                    self.decode_tool_call(func_call)
                #如果没有异常，说明json格式正常
                break
            except json.JSONDecodeError as e:
                self.env.manual_log('Admin', f"警告：输出内容的JSON格式可能被破坏，错误信息：{str(e)}，进行第 {str(error_counter + 1)} 次重试")
                
                error_counter += 1
                #call llm again to fix the error
                response = self.agent.model_client.chat.completions.create(
                    model=self.agent.MODEL_NAME,
                    messages=messages,
                    max_tokens=self.agent.MAX_TOKENS,
                    stream=True,
                    tools=self.get_tools_description(),
                    tool_choice = "required" if tools_enable else "none"
                )

        if func_call_list:
            self.update_short_term_memory({
                "role": "assistant",
                "content": message,
                "tool_calls": func_call_list
            })
        else:
            self.update_short_term_memory({
                "role": "assistant",
                "content": message

            })
        return message, func_call_list

    def handle_chat_response(self, response):
        status = 0
        message = ""
        func_call_list = []
        tool_status = 0
        for chunk in response:
            for choice in chunk.choices:
                if hasattr(choice.delta, "tool_calls") and choice.delta.tool_calls:
                    for index, tcchunk in enumerate(choice.delta.tool_calls):
                        if len(func_call_list) <= index:
                            func_call_list.append({
                                "id": "",
                                "name": "",
                                "type": "function", 
                                "function": { "name": "", "arguments": "" } 
                            })
                        tc = func_call_list[index]
                        if tcchunk.id:
                            tc["id"] += tcchunk.id
                        if tcchunk.function.name:
                            tc["function"]["name"] += tcchunk.function.name
                        if tcchunk.function.arguments:
                            if tool_status == 0:
                                tool_status = 1
                                self.env.manual_log(self.name, "调用工具：")
                            #将 tcchunk.function.arguments 中的 \n 替换为真的换行符，改善log的可读性
                            tcchunk_logging = tcchunk.function.arguments.replace('\\n', '\n')
                            self.env.manual_log(self.name, tcchunk_logging, False)
                            tc["function"]["arguments"] += tcchunk.function.arguments 
                if hasattr(choice.delta, "reasoning_content") and choice.delta.reasoning_content:
                    if status != 1:
                        status = 1
                        self.env.manual_log(self.name, "思考：")
                    self.env.manual_log(self.name, choice.delta.reasoning_content, False)
                if hasattr(choice.delta, "content") and choice.delta.content:
                    if status != 2:
                        status = 2
                        self.env.manual_log(self.name, "输出：")
                    self.env.manual_log(self.name, choice.delta.content, False)
                    message += choice.delta.content
        return message,func_call_list
