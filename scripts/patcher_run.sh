#!/bin/bash

# TODO 构建时暂存源码树中的工具软链目录；每个checkout使用独立stash与互斥锁。
# TODO 中断时保留恢复清单；遇到目标冲突立即停止，不覆盖用户新文件。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
IDENTITY="$(printf '%s' "$ROOT" | shasum -a 256 | cut -c1-16)"
STASH="$(dirname "$ROOT")/.topread_patcher_stash_$IDENTITY"
LOCK="$STASH.lock"
MANIFEST="$STASH/.manifest"
# TODO 内核互斥锁在异常退出后自动释放，不通过删除PID文件争抢过期锁。
if [ "${TOPREAD_PATCHER_LOCK_ROOT:-}" != "$ROOT" ]; then
    if command -v lockf >/dev/null 2>&1; then
        exec env TOPREAD_PATCHER_LOCK_ROOT="$ROOT" lockf -k -t 0 "$LOCK" bash "$ROOT/scripts/patcher_run.sh" "$@"
    elif command -v flock >/dev/null 2>&1; then
        exec env TOPREAD_PATCHER_LOCK_ROOT="$ROOT" flock -n "$LOCK" bash "$ROOT/scripts/patcher_run.sh" "$@"
    fi
    echo "热更构建需要系统lockf或flock以保护暂存目录" >&2
    exit 1
fi
fvm dart run "$ROOT/scripts/check_managed_sdk.dart"
mkdir -p "$STASH"

restore() {
    result=0
    if [ -f "$MANIFEST" ]; then
        while IFS= read -r relative; do
            [ -z "$relative" ] && continue
            if [ -e "$STASH/$relative" ] || [ -L "$STASH/$relative" ]; then
                if [ -e "$ROOT/$relative" ] || [ -L "$ROOT/$relative" ]; then
                    echo "恢复冲突，已保留原文件：$STASH/$relative；目标：$ROOT/$relative" >&2
                    result=1
                else
                    mkdir -p "$(dirname "$ROOT/$relative")"
                    mv "$STASH/$relative" "$ROOT/$relative" || result=1
                fi
            fi
        done < "$MANIFEST"
        if [ "$result" -eq 0 ]; then rm -f "$MANIFEST"; fi
    fi
    rmdir "$STASH" 2>/dev/null || true
    return "$result"
}
finish() {
    code=$?
    trap - EXIT
    if ! restore; then code=1; fi
    exit "$code"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# TODO 上次中断清单先恢复；新的目录冲突由restore保留两份并报错。
if [ -f "$MANIFEST" ]; then
    while IFS= read -r relative; do
        [ -z "$relative" ] && continue
        if [ -e "$STASH/$relative" ] || [ -L "$STASH/$relative" ]; then
            if [ -e "$ROOT/$relative" ] || [ -L "$ROOT/$relative" ]; then
                echo "暂存恢复存在冲突：$relative；请检查 $STASH" >&2
                exit 1
            fi
            mkdir -p "$(dirname "$ROOT/$relative")"
            mv "$STASH/$relative" "$ROOT/$relative"
        fi
    done < "$MANIFEST"
fi
: > "$MANIFEST"
TARGETS=()
for relative in .fvm caches daemon native wrapper flutter_sdk .tmp; do
    [ ! -d "$relative" ] || TARGETS+=("$relative")
done
while IFS= read -r directory; do TARGETS+=("${directory#./}"); done < <(
    find . -type d -name node_modules -prune \
        -not -path './ios/Pods/*' -not -path './macos/Pods/*' \
        -not -path './build/*' -not -path './.git/*' -not -path './.dart_tool/*'
)
for relative in "${TARGETS[@]+"${TARGETS[@]}"}"; do
    mkdir -p "$STASH/$(dirname "$relative")"
    # TODO 先写恢复清单，SIGKILL发生在mv之后也能在下一次恢复。
    printf '%s\n' "$relative" >> "$MANIFEST"
    mv "$relative" "$STASH/$relative"
done
PATH="$ROOT/scripts/shims:$PATH" "$@"
