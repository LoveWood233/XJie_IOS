#!/bin/bash
# 双击此文件即可将当前项目安全更新到 upstream/main。
# 本地改动会临时储藏并在更新后恢复；出现分叉或恢复冲突时停止，不覆盖本地内容。

set -u

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
STASH_CREATED=0
EXIT_CODE=0

finish() {
    if [[ -t 0 ]]; then
        echo
        read -r -n 1 -p "按任意键关闭窗口…" || true
        echo
    fi
    exit "$1"
}

cd "$PROJECT_DIR" || finish 1

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "错误：脚本必须放在 Git 项目根目录中。"
    finish 1
fi

if ! git remote get-url upstream >/dev/null 2>&1; then
    echo "错误：未配置 upstream 远程仓库。"
    finish 1
fi

echo "正在获取 upstream/main…"
if ! git fetch upstream main; then
    echo "获取失败：请检查网络、GitHub 登录状态和 upstream 配置。"
    finish 1
fi

if git merge-base --is-ancestor upstream/main HEAD; then
    echo "当前代码已包含最新 upstream/main。"
    git status --short --branch
    finish 0
fi

if ! git merge-base --is-ancestor HEAD upstream/main; then
    echo "已停止：当前分支与 upstream/main 已分叉，不能安全快进。"
    echo "请先人工处理本地提交，再重新执行此脚本。"
    git status --short --branch
    finish 1
fi

if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    echo "正在临时保护本地未提交和未跟踪文件…"
    if ! git stash push --include-untracked --message "update-upstream-main-$(date +%Y%m%d-%H%M%S)"; then
        echo "无法保护本地修改，更新已取消。"
        finish 1
    fi
    STASH_CREATED=1
fi

echo "正在快进到 upstream/main…"
if ! git merge --ff-only upstream/main; then
    echo "更新失败，未执行覆盖操作。"
    EXIT_CODE=1
fi

if [[ "$STASH_CREATED" -eq 1 ]]; then
    echo "正在恢复本地修改…"
    if ! git stash pop; then
        echo "本地修改恢复时出现冲突；Git 已保留 stash，请解决冲突后再继续。"
        EXIT_CODE=1
    fi
fi

git status --short --branch

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "更新完成：$(git rev-parse --short HEAD)"
fi
finish "$EXIT_CODE"
