from agent import WolfSiliconAgent
import argparse
import os
import datetime

def create_workspace(rootpath,name):
    # 在rootpath创建一个以日期时间编号的 wksp_YYYYMMDD_HHMMSS 文件夹
    workpath = os.path.join(rootpath, f"{name}_{datetime.datetime.now().strftime('%m%d_%H%M%S')}")
    workpath = os.path.abspath(workpath)
    os.makedirs(workpath)
    # 复制mkfile和filelist到工作目录
    mkfile_path = os.path.join('makefile', "Makefile")
    #filelist_path = os.path.join('makefile', "filelist.f")
    os.system(f"cp {mkfile_path} {workpath}")
    #os.system(f"cp {filelist_path} {workpath}")
    return workpath

if __name__ == "__main__":
    # 设置可选参数 --req 
    parser = argparse.ArgumentParser()
    parser.add_argument("--req", type=str, help="User requirements file path")
    parser.add_argument("--name",type=str, help="Name of workspace", default="wksp",required=False)
    parser.add_argument("--workpath", type=str, help="Workspace root path",required=False)
    parser.add_argument("--start_from", type=str, help="Start from a specific step (project, design, verification)", 
                        choices=["project", "design", "verification", "iter"], default="project", required=False)
    args = parser.parse_args()
    # 在指定目录下创建工作目录
    if args.workpath:
        workpath = os.path.join("./", args.workpath)
        workpath = os.path.abspath(workpath)
    else:
        workpath = create_workspace("./playground",args.name)
    # 创建 WolfSiliconAgent
    agent = WolfSiliconAgent(workspace_path=workpath, user_requirements_path=args.req, start_from=args.start_from)
    if agent.run() == 0:
        exit