# 定义需要进行 lint 检查的 Verilog 源文件列表
SRCS = top.v

VCS = vlogan
VCS_OPTS = -full64 

# 定义伪目标，确保每次调用时都重新执行命令
.PHONY: all lint clean

# 默认目标为 lint
all: lint

# lint 目标：调用 VCS 对代码进行 lint 检查
lint:
	@echo "Running lint on Verilog sources..."
	$(VCS) $(VCS_OPTS) -f $(SRCS)
	@if [ $$? -eq 0 ]; then \
		echo "Lint finished successfully."; \
	else \
		echo "Lint found issues."; \
	fi

# clean 目标：清理 VCS 编译过程中产生的文件和目录
clean:
	rm -rf csrc vcs.key vcs.log simv* *.daidir work
