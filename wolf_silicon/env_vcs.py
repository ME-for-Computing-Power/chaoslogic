import datetime
import subprocess
import threading
import queue
import os
import re

import sys
import itertools
import textwrap
import signal
class WolfSiliconEnv(object):
    
    def __init__(self, workspace_path:str, doc_path:str, cmodel_path:str, design_path:str, verification_path:str, model_client:object, translation_model_name:str=None):
        self._workspace_path = workspace_path
        self._doc_path = doc_path
        self._cmodel_path = cmodel_path
        self._design_path = design_path
        self._verification_path = verification_path

        self._user_requirements_path = os.path.join(self._doc_path, "user_requirements.md")
        self._spec_path = os.path.join(self._doc_path, "spec.md")
        self._cmodel_code_path = os.path.join(self._cmodel_path, "cmodel.cpp")
        self._cmodel_binary_path = os.path.join(self._cmodel_path, "cmodel")
        self._design_code_path = os.path.join(self._design_path, "dut.v")
        self._design_filelist_path = os.path.join(self._design_path, "filelist")
        self._verification_code_path = os.path.join(self._verification_path, "tb.sv")
        self._verification_feedback_path = os.path.join(self._doc_path, "feedback.md")
        self._verification_binary_path = os.path.join(self._workspace_path, "simv")
        self._verification_report_path = os.path.join(self._doc_path, "verification_report.md")
        self._log_path = os.path.join(self._doc_path, "log.txt")

        self.model_client = model_client
        self.translation_model_name = translation_model_name

    def write_user_requirements(self, requirements:str):
        # 将 requirements 写入 {self._doc_path}/user_requirements.md，固定为追加写入
        with open(self._user_requirements_path, "a") as f:
            f.write(requirements+"\n")
    
    def get_user_requirements(self) -> tuple[bool, float, str]:
        # 返回 user requirements 的内容和修改时间
        if os.path.exists(self._user_requirements_path):
            mtime = os.path.getmtime(self._user_requirements_path)
            with open(self._user_requirements_path, "r") as f:
                return True, mtime, f.read()
        else:
            return False, 0, "No user requirements found."
        
    def write_spec(self, spec:str, overwrite:bool=False):
        # 将 spec 写入 {self._doc_path}/spec.md，如果 overwrite 为 False，追加写入
        with open(self._spec_path, "w" if overwrite else "a") as f:
            f.write(spec+"\n")
    
    def get_spec(self) -> tuple[bool, float, str]:
        if os.path.exists(self._spec_path):
            mtime = os.path.getmtime(self._spec_path)
            with open(self._spec_path, "r") as f:
                return True, mtime, f.read()
        else:
            return False, 0, "No spec found."
    
    def write_cmodel_code(self, code:str):
        # 将 cmodel code 写入 {self._cmodel_path}/cmodel.cpp, 固定为 overwrite
        with open(self._cmodel_code_path, "w") as f:
            f.write(code+"\n")
    
    def get_cmodel_code(self) -> tuple[bool, float, str]:
        # 返回 cmodel code 的内容和修改时间
        if os.path.exists(self._cmodel_code_path):
            mtime = os.path.getmtime(self._cmodel_code_path)
            with open(self._cmodel_code_path, "r") as f:
                return True, mtime, f.read()
        else:
            return False, 0, "No cmodel code found."
    
    def delete_cmodel_binary(self):
        # 删除 {self._cmodel_path}/cmodel
        if os.path.exists(self._cmodel_binary_path):
            os.remove(self._cmodel_binary_path)
    
    def is_cmodel_binary_exist(self) -> bool:
        # 判断 {self._cmodel_path}/cmodel 是否存在
        return os.path.exists(self._cmodel_binary_path)
    
    def compile_cmodel(self) -> str:
        # 获取 codebase 中所有 .cpp 文件
        cpp_files = []
        for filename in os.listdir(self._cmodel_path):
            if filename.endswith('.cpp'):
                cpp_files.append(os.path.join(self._cmodel_path,filename))
        result = WolfSiliconEnv.execute_command(f"g++  {' '.join(cpp_files)} -I{self._cmodel_path} -o {self._cmodel_path}/cmodel", 300)
        return result[-4*1024:]
    
    def run_cmodel(self, timeout_sec:int=180) -> str:
        # 运行 cmodel binary
        result = WolfSiliconEnv.execute_command(self._cmodel_binary_path, timeout_sec)
        return result[-4*1024:]
    
    def compile_and_run_cmodel(self):
        self.delete_cmodel_binary()
        compiler_output = self.compile_cmodel()
        if not self.is_cmodel_binary_exist():
            return f"# No cmodel binary found. Compile failed.\n Here is the compiler output \n{compiler_output}"
        else:
            cmodel_output = self.run_cmodel()
            return f"# CModel compiled successfully. Please review the output from the run. \n{cmodel_output}"
    
    def write_design_code(self, code:str):
        # 将 design code 写入 {self._design_path}/dut.v, 固定为 overwrite
        with open(self._design_code_path, "w") as f:
            f.write(code+"\n")
    
    def get_design_code(self) -> tuple[bool, float, str]:
        # 返回 design code 的内容和修改时间
        if os.path.exists(self._design_code_path):
            mtime = os.path.getmtime(self._design_code_path)
            with open(self._design_code_path, "r") as f:
                return True, mtime, f.read()
        else:
            return False, 0, "No design code found."
    
    def lint_design(self) -> str:
        # 获取 codebase 中所有 .v 文件
        v_files = []
        for filename in os.listdir(self._design_path):
            if filename.endswith('.v'):
                v_files.append(os.path.join(self._design_path,filename))
        # 保存到 filelist 文件中
        with open(self._design_filelist_path, "w") as f:
            for filepath in v_files:
                f.write(filepath + "\n")
        # lint 不使用 execute command，直接使用 os.system vlogan -full64  -f filelist.f -l test.log
        command = f"vlogan -full64  -f {self._design_filelist_path} -sverilog"
        with subprocess.Popen(command.split(' '), 
                      stdout=subprocess.PIPE, 
                      stderr=subprocess.PIPE,
                      text=True) as process:
            stdout, stderr = process.communicate()
        output = stdout + stderr
        # Remove the matched block
        cleaned_log = re.sub(r'^.*?(Parsing design file .*)', r'\1', output, flags=re.DOTALL)
        print(cleaned_log)
        return cleaned_log
    
    def write_verification_code(self, code:str):
        # 将 verification code 写入 {self._verification_path}/tb.sv, 固定为 overwrite
        with open(self._verification_code_path, "w") as f:
            f.write(code+"\n")
        
    def write_feedback(self, text:str):
        with open(self._verification_feedback_path, "w") as f:
            f.write(text+"\n")

    def get_feedback(self) -> tuple[bool, float, str]:
        if os.path.exists(self._verification_feedback_path):
            mtime = os.path.getmtime(self._verification_feedback_path)
            with open(self._verification_feedback_path, "r") as f:
                return True, mtime, f.read()
        else:
            return False, 0, "No feedback found."
        
    def get_verification_code(self) -> tuple[bool, float, str]:
        # 返回 verification code 的内容和修改时间
        if os.path.exists(self._verification_code_path):
            mtime = os.path.getmtime(self._verification_code_path)
            with open(self._verification_code_path, "r") as f:
                return True, mtime, f.read()
        else:
            return False, 0, "No verification code found."
    
    def compile_verification(self) -> str:
        # code_file = []
        # for filename in os.listdir(self._verification_path):
        #     if filename.endswith('.v') or filename.endswith('.sv'):
        #         code_file.append(os.path.join(self._verification_path, filename))
        # for filename in os.listdir(self._design_path):
        #     if filename.endswith('.v'):
        #         code_file.append(os.path.join(self._design_path, filename))
        # # 保存到 filelist 文件中
        # with open(self._design_filelist_path, "w") as f:
        #     for filepath in code_file:
        #         f.write(filepath + "\n")
        current_path = os.getcwd()
        os.chdir(self._workspace_path)
        result = WolfSiliconEnv.execute_command(f"make run", 300)
        os.chdir(current_path)
        cleaned_log = re.sub(r'^.*?(Parsing design file .*)', r'\1', result, flags=re.DOTALL)
        print(cleaned_log)
        
        return cleaned_log

    def is_verification_binary_exist(self) -> bool:
        return os.path.exists(self._verification_binary_path)
    
    def run_verification(self, timeout_sec:int=300) -> str:
        result = WolfSiliconEnv.execute_command(self._verification_binary_path + " "+"+vcs+finish+999999" , timeout_sec)
        print(result)
        return result
    
    def compile_and_check_verification(self) -> str:
        self.delete_verification_binary()
        compiler_output = self.compile_verification()
        if not self.is_verification_binary_exist():
            return f"# 编译错误\n 报错如下：\n{compiler_output}"
        else:
            return 'Success'
        
    def compile_and_run_verification(self) -> str:
        self.delete_verification_binary()
        compiler_output = self.compile_verification()
        if not self.is_verification_binary_exist():
            return f"# 编译错误\n 报错如下：\n{compiler_output}"
        else:
            verification_output = self.run_verification()
            return f"# 编译成功！\n 请审阅输出：\n{verification_output}"
    
    def delete_verification_binary(self):
        if os.path.exists(self._verification_binary_path):
            os.remove(self._verification_binary_path)
    
    def write_verification_report(self, report:str):
        # 将 verification report 写入 {self._doc_path}/verification_report.md，固定为 overwrite
        with open(self._verification_report_path, "w") as f:
            f.write(report+"\n")
    
    def get_verification_report(self) -> tuple[bool, float, str]:
        # 返回 verification report 的内容和修改时间
        if os.path.exists(self._verification_report_path):
            mtime = os.path.getmtime(self._verification_report_path)
            with open(self._verification_report_path, "r") as f:
                return True, mtime, f.read()
        else:
            return False, 0, "No verification report found."
    def compress_lines( text: str) -> str:
        """
        将连续重复的行压缩为“内容 [重复 N 次]”形式。
        例如：
        A
        A
        A
        B
        B
        会被压缩为：
        A [重复 3 次]
        B [重复 2 次]
        """
        lines = text.splitlines()
        compressed = []
        for line, group in itertools.groupby(lines):
            count = sum(1 for _ in group)
            if count > 5:
                compressed.append(f"{line}  [重复 {count} 次]")
            else:
                compressed.append(line)
        # 保留末尾可能缺少的 '\n'
        return "\n".join(compressed) + ("\n" if text.endswith("\n") else "")
    
    def execute_command(command: str, timeout_sec: float) -> str:
        """
        在 Linux shell 中执行给定的命令字符串，并捕获所有输出和错误。
        如果超过 timeout_sec 秒仍未结束，则强制终止进程，并返回包括超时信息、
        已产生的输出和错误在内的完整日志。

        :param command: 要执行的 shell 命令
        :param timeout_sec: 最长允许运行时间（秒）
        :return: 包含 stdout、stderr 以及可能的超时提示的完整字符串
        """
        # 启动一个新的进程组，以便后面能一并终止所有子进程
        proc = subprocess.Popen(
            command,
            shell=True,
            executable="/bin/bash",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            preexec_fn=os.setsid
        )
        pid = proc.pid
        print ("PID is ", pid) 
        try:
            stdout, stderr = proc.communicate(timeout=timeout_sec)
            output = textwrap.dedent(f"""\
                --- STDOUT ---
                {stdout}
                --- STDERR ---
                {stderr}""")
            return WolfSiliconEnv.compress_lines(output)
        except subprocess.TimeoutExpired:
            # 超时：终止整个进程组
            os.killpg(proc.pid, signal.SIGTERM)
            # 再次收集可能已有的输出
            stdout, stderr = proc.communicate()
            output = textwrap.dedent(f"""\
                [超时，已在 {timeout_sec:.1f} 秒后终止]
                --- STDOUT（超时内容） ---
                {stdout}
                --- STDERR（超时内容） ---
                {stderr}""")
            return WolfSiliconEnv.compress_lines(output)


    def manual_log(self, name, message, newline=True):
       with open(self._log_path, "a") as f:
            if newline:
                log_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                log_content = f"\n【 {log_time} {name} 】\n\n{message}"
            else:
                log_content = f"{message}"
            print(log_content, end="")
            sys.stdout.flush()
            f.write(log_content)
