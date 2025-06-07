import shutil

if shutil.which("vcs"):
    from env_vcs import WolfSiliconEnv
elif shutil.which("verilator"):
    from env_verilator import WolfSiliconEnv
else:
    raise RuntimeError("Neither VCS nor Verilator found in PATH. Please install one of them to proceed.")

import os
from project_manager_assistant import ProjectManagerAssistant
from cmodel_engineer_assistant import CModelEngineerAssistant
from design_engineer_assistant import DesignEngineerAssistant
from verification_engineer_assistant import VerificationEngineerAssistant
from model_client import mc

class WolfSiliconAgent(object):
    def __init__(self, workspace_path, user_requirements_path=None, 
                 user_cmodel_code_path=None, 
                 user_design_code_path=None,
                 user_verification_code_path=None,
                 start_from="project") -> None:
        # config
        self.MODEL_NAME = "deepseek-reasoner"
        self.TRANSLATION_MODEL_NAME = "deepseek-reasoner"
        self.MAX_SHORT_TERM_MEMORY = 10
        self.MAX_RETRY = 10
        self.MAX_TOKENS = 32000
        # connect to model_client
        self.model_client = mc
        # 在 workspace 目录下创建doc、cmodel、design、verification文件夹
        self.workspace_path = workspace_path
        self.doc_path = os.path.join(workspace_path, "doc")
        self.cmodel_path = os.path.join(workspace_path, "cmodel")
        self.design_path = os.path.join(workspace_path, "design")
        self.verification_path = os.path.join(workspace_path, "verification")
        self.start_from = start_from
        os.makedirs(self.doc_path, exist_ok=True)
        os.makedirs(self.cmodel_path, exist_ok=True)
        os.makedirs(self.design_path, exist_ok=True)
        os.makedirs(self.verification_path, exist_ok=True)
        self.env = WolfSiliconEnv(self.workspace_path, self.doc_path, self.cmodel_path, 
                                  self.design_path, self.verification_path, 
                                  self.model_client, self.TRANSLATION_MODEL_NAME)
        # 初始化环境
        # 读取用户需求，写入user_requirements.md
        if user_requirements_path:
            with open(user_requirements_path, "r") as f:
                user_requirements = f.read()
                self.env.write_user_requirements(user_requirements)
        else: # 用户未提供输入文件，提示用户输入需求
            user_requirements = input("\n 用户输入: ")
            self.env.write_user_requirements(user_requirements)
        if user_cmodel_code_path:
            # 如果用户提供了 C++ CModel 代码路径，复制其中文件到 cmodel 文件夹
            for filename in os.listdir(user_cmodel_code_path):
                os.copy(os.path.join(user_cmodel_code_path, filename), self.cmodel_path)
        if user_design_code_path:
            # 如果用户提供了 Verilog 设计代码路径，复制其中文件到 design 文件夹
            for filename in os.listdir(user_design_code_path):
                os.copy(os.path.join(user_design_code_path, filename), self.design_path)
        if user_verification_code_path:
            # 如果用户提供了 SystemVerilog 验证代码路径，复制其中文件到 verification 文件夹
            for filename in os.listdir(user_verification_code_path):
                os.copy(os.path.join(user_verification_code_path, filename), self.verification_path)
        # 创建 AssistantAgent
        # TODO
        self.project_manager_assistent = ProjectManagerAssistant(self)
        self.cmodel_engineer_assistant = CModelEngineerAssistant(self)
        self.design_engineer_assistant = DesignEngineerAssistant(self)
        self.verification_engineer_assistant = VerificationEngineerAssistant(self)

    def run(self):
        first_loop = True
        res = "design"
        try:
            while True:
                if not first_loop or self.start_from == "project":
                    res = self.project_manager_assistent.execute()
                    first_loop = False
                if res == "design":
                    #self.cmodel_engineer_assistant.execute()
                    if not first_loop or self.start_from == "design":
                        self.design_engineer_assistant.execute()
                        first_loop = False
                    if not first_loop or self.start_from == "verification":
                        self.verification_engineer_assistant.execute()
                        first_loop = False
                else:
                    print("\n**** 完成 ****\n")
                    return 0
        except KeyboardInterrupt:
            print("\n键盘输入中断")

