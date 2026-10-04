#!/bin/bash
# 安裝 Mark It Down 快速動作到 ~/Library/Services，並確保 markitdown 可用
# 用法：install.sh [--lang en|zh]   （預設依系統語言）
set -uo pipefail
cd "$(dirname "$0")" || exit 1

while [ "$#" -gt 0 ]; do
  case "$1" in
    --lang) export MD_LANG="${2:-}"; shift 2 ;;
    *) echo "Usage: $0 [--lang en|zh]" >&2; exit 2 ;;
  esac
done
# shellcheck source=src/lib.sh
source src/lib.sh

[ "$(uname)" = Darwin ] || { t i_macos_only >&2; echo >&2; exit 1; }

# 建置到暫存資料夾，不在安裝來源（例如 Homebrew 的 keg）裡寫檔
DIST="$(mktemp -d)" || exit 1
trap 'rm -rf "$DIST"' EXIT
python3 build.py "$DIST" "$MD_L" >/dev/null || { t i_build_fail >&2; echo >&2; exit 1; }

mkdir -p "$HOME/Library/Services" || exit 1
# 先清掉舊版（含另一種語言的名稱），避免切換語言後留下兩組
for old in "$HOME/Library/Services/Mark It Down - "*.workflow; do
  [ -e "$old" ] && rm -rf "$old"
done
for w in "$DIST"/*.workflow; do
  cp -R "$w" "$HOME/Library/Services/" || { t i_copy_fail "$w" >&2; echo >&2; exit 1; }
  t i_installed "$(basename "$w")"; echo
done
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

if command -v markitdown >/dev/null 2>&1; then
  t i_md_have "$(command -v markitdown)"; echo
else
  t i_md_installing; echo
  install_markitdown || { t i_md_fail >&2; echo >&2; exit 1; }
fi
t i_done; echo
t i_hint; echo
