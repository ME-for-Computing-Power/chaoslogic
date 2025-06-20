#!/bin/bash

# 遍历所有 .md 文件
find . -type f -name "*.md" | while read -r mdfile; do
    abs_mdfile=$(realpath "$mdfile")             # 获取绝对路径
    dir=$(dirname "$abs_mdfile")                 # 提取所在目录
    filename=$(basename "$abs_mdfile" .md)       # 提取不含后缀的文件名
    output_pdf="${filename}.pdf"                 # 输出文件（当前目录下）

    echo "Converting: $filename.md in $dir"

    # 切换到文件所在目录执行转换命令
    (
        cd "$dir" || exit 1
        pandoc -i "$filename.md" -o "$output_pdf" \
            --pdf-engine=xelatex \
            -V fontsize=12pt \
            -V mainfont="Noto Serif CJK SC" \
            -V monofont="Noto Sans Mono CJK SC" \
            --template pm
    )

    # 判断转换是否成功
    if [ $? -eq 0 ]; then
        echo "✅ Success: ${dir}/${output_pdf}"
    else
        echo "❌ Failed: ${dir}/${filename}.md" >&2
    fi
done
