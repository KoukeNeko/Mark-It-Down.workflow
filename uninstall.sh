#!/bin/bash
# 移除 Mark It Down 快速動作。加 --purge 連 markitdown 本體一併移除
set -uo pipefail
cd "$(dirname "$0")" || exit 1

purge=0
case "${1:-}" in
  "") ;;
  --purge) purge=1 ;;
  *) echo "用法：$0 [--purge]" >&2; exit 2 ;;
esac

# shellcheck source=src/lib.sh
source src/lib.sh

removed=0
for w in "$HOME/Library/Services/Mark It Down - "*.workflow; do
  [ -e "$w" ] || continue
  rm -rf "$w" && { echo "removed: $(basename "$w")"; removed=$((removed + 1)); }
done
[ "$removed" -eq 0 ] && echo "找不到已安裝的快速動作（可能已經移除）"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

# 本工具自建的虛擬環境與連結一定可以清；連結只有指向該環境時才刪
link="$HOME/.local/bin/markitdown"
if [ -L "$link" ] && [ "$(readlink "$link")" = "$MD_VENV/bin/markitdown" ]; then
  rm -f "$link" && echo "removed: $link"
fi
[ -d "$MD_VENV" ] && rm -rf "$MD_VENV" && echo "removed: $MD_VENV"

if [ "$purge" -eq 1 ]; then
  if command -v uv >/dev/null 2>&1 && uv tool list 2>/dev/null | grep -q '^markitdown'; then
    uv tool uninstall markitdown
  fi
  if command -v pipx >/dev/null 2>&1 && pipx list --short 2>/dev/null | grep -q '^markitdown'; then
    pipx uninstall markitdown
  fi
elif command -v markitdown >/dev/null 2>&1; then
  echo "保留 markitdown（$(command -v markitdown)）；要一併移除請執行：$0 --purge"
fi
echo "完成！"
