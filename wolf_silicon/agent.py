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
from model_client import mc, model_name

class WolfSiliconAgent(object):
    def __init__(self, workspace_path, user_requirements_path=None, 
                 user_cmodel_code_path=None, 
                 user_design_code_path=None,
                 user_verification_code_path=None,
                 user_veri_plan_path=None,
                 start_from="project",
                 use_spec=False) -> None:
        # config
        self.MODEL_NAME = model_name #在 model_client.py 中定义
        #self.TRANSLATION_MODEL_NAME = "deepseek-reasoner"
        self.MAX_SHORT_TERM_MEMORY = 4
        self.MAX_RETRY = 5
        self.MAX_TOKENS = 16384
        # connect to model_client
        self.model_client = mc
        # 在 workspace 目录下创建doc、cmodel、design、verification文件夹
        self.workspace_path = workspace_path
        self.doc_path = os.path.join(workspace_path, "doc")
        self.cmodel_path = os.path.join(workspace_path, "cmodel")
        self.design_path = os.path.join(workspace_path, "design")
        self.verification_path = os.path.join(workspace_path, "verification")
        self.ref_model_path = os.path.join(workspace_path, "ref_model")
        self.start_from = start_from
        self.use_spec = use_spec
        os.makedirs(self.doc_path, exist_ok=True)
        os.makedirs(self.cmodel_path, exist_ok=True)
        os.makedirs(self.design_path, exist_ok=True)
        os.makedirs(self.verification_path, exist_ok=True)
        os.makedirs(self.ref_model_path, exist_ok=True)
        self.env = WolfSiliconEnv(self.workspace_path, self.doc_path, self.cmodel_path, 
                                  self.design_path, self.verification_path, 
                                  self.model_client)
        # 初始化环境
        # 读取用户需求，写入user_requirements.md
        if user_requirements_path:
            requirements_path = os.path.join(user_requirements_path, "requirements.md")
            with open(requirements_path, "r") as f:
                user_requirements = f.read()
                self.env.write_user_requirements(user_requirements)
            veri_plan_path = os.path.join(user_requirements_path, "veri_plan.md")
            with open(veri_plan_path, "r") as f:
                veri_plan = f.read()
                self.env.write_veri_plan(veri_plan)
            ref_model_path = os.path.join(user_requirements_path, "ref_model")
            #找到所有以.v结尾的文件，复制到verification_path
            for filename in os.listdir(ref_model_path):
                if filename.endswith('.v') or filename.endswith('.sv'):
                    shutil.copy(os.path.join(ref_model_path, filename), self.ref_model_path)
        if self.start_from == 'spec':
            # 如果用户提供了 spec，写入 spec.md
            spec_path = os.path.join(user_requirements_path, "spec.md")
            with open(spec_path, "r") as f:
                spec = f.read()
                self.env.write_spec(spec, overwrite=True)    
        # else: # 用户未提供输入文件，提示用户输入需求
        #     user_requirements = input("\n 用户输入: ")
        #     self.env.write_user_requirements(user_requirements)
        # if user_cmodel_code_path:
        #     # 如果用户提供了 C++ CModel 代码路径，复制其中文件到 cmodel 文件夹
        #     for filename in os.listdir(user_cmodel_code_path):
        #         os.copy(os.path.join(user_cmodel_code_path, filename), self.cmodel_path)
        # if user_design_code_path:
        #     # 如果用户提供了 Verilog 设计代码路径，复制其中文件到 design 文件夹
        #     for filename in os.listdir(user_design_code_path):
        #         os.copy(os.path.join(user_design_code_path, filename), self.design_path)
        # if user_verification_code_path:
        #     # 如果用户提供了 SystemVerilog 验证代码路径，复制其中文件到 verification 文件夹
        #     for filename in os.listdir(user_verification_code_path):
        #         os.copy(os.path.join(user_verification_code_path, filename), self.verification_path)
        # 创建 AssistantAgent
        self.project_manager_assistent = ProjectManagerAssistant(self)
        self.cmodel_engineer_assistant = CModelEngineerAssistant(self)
        self.design_engineer_assistant = DesignEngineerAssistant(self)
        self.verification_engineer_assistant = VerificationEngineerAssistant(self)

    def run(self):
        first_loop = True
        res = "design"
        if self.start_from != 'project':
            if self.start_from not in ["project", "design", "verification", "iter", "spec"]:
                raise ValueError("start_from must be one of 'project', 'design', 'verification', or 'iter'")
            self.env.manual_log("Admin", f"从{self.start_from} 状态断点复原")
        try:
            while True:
                if not first_loop or self.start_from == "project":
                    res = self.project_manager_assistent.execute()
                    first_loop = False
                if self.start_from == "spec":
                    first_loop = False
                if res == "design":
                    #self.cmodel_engineer_assistant.execute()
                    if not first_loop or self.start_from == "design":
                        self.design_engineer_assistant.execute()
                        first_loop = False
                    if not first_loop or self.start_from == "verification" or self.start_from == "iter":
                        first_loop = False
                        i=0
                        if self.start_from == "iter":#认为iter状态是指验证工程师检查到设计工程师的设计有错误，已完成feedback.md文件
                            self.start_from == 'project'#删除start_from
                            self.design_engineer_assistant.state = 'design_error'
                            self.verification_engineer_assistant.state = 'error_in_design'
                            self.design_engineer_assistant.execute()
                        while True:#循环一直执行，直到验证工程师认为设计工程师没有错误
                            if self.verification_engineer_assistant.execute() != 'Error in Design' :
                                break
                            i+=1
                            iter_msg = "验证工程师发起了第"+str(i)+"次迭代"
                            self.env.manual_log("Admin",iter_msg)
                            self.design_engineer_assistant.state = 'design_error'
                            self.design_engineer_assistant.execute()
                else:
                    print("\n**** 完成 ****\n")
                    return 0
        except KeyboardInterrupt:
            print("\n键盘输入中断")

