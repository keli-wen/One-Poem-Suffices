#!/bin/zsh
# 编译 Agent Skills PDF（onepoem.cls 在上级目录）
set -e
cd "$(dirname "$0")"
export TEXINPUTS=..:
xelatex -interaction=nonstopmode main.tex
xelatex -interaction=nonstopmode main.tex
mv main.pdf agent-skills.pdf
rm -f main.aux main.log main.out main.listing
echo "✓ agent-skills.pdf"
# 导出小红书图片：pdftoppm -png -r 300 agent-skills.pdf xhs-page
