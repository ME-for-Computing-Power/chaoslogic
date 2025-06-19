# 使用说明

## 环境准备


- `pip install openai`

- 安装VCS，开发时使用了vcs18版

## 准备配置文件

在 `chaos_logic` 目录下创建 `model_client.py` 文件，填入你的API KEY和服务地址内容如下：

```python
from openai import OpenAI

mc = OpenAI(
    api_key="xxx",
    base_url="https://xxx.com/api",
)
model_name = "deepseek-r1-250528"#or your model
```

### 确认模型类型

`chaos_logic/agent.py` 中可指定调用的模型名称，目前主要使用 ds-reasoner进行推理

```python
class chaoslogicAgent(object):
    def __init__(self,...) -> None:
        # config
        self.MODEL_NAME = "
        # ...
```


### 运行

```bash
python3 chaos_logic/main.py --req /path/to/req --name "test"
```

