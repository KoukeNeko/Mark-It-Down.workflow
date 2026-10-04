#!/bin/bash
# 移除 Mark It Down 快速動作。加 --purge 連 markitdown 本體一併移除
set -uo pipefail
cd "$(dirname "$0")" || exit 1

purge=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --purge) purge=1; shift ;;
    --lang) export MD_LANG="${2:-}"; shift 2 ;;
    *) source src/lib.sh; t u_usage "$0" >&2; echo >&2; exit 2 ;;
  esac
done
# shellcheck source=src/lib.sh
source src/lib.sh

removed=0
for w in "$HOME/Library/Services/Mark It Down - "*.workflow; do
  [ -e "$w" ] || continue
  rm -rf "$w" && { t u_removed "$(basename "$w")"; echo; removed=$((removed + 1)); }
done
[ "$removed" -eq 0 ] && { t u_none; echo; }
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

# 本工具自建的虛擬環境與連結一定可以清；連結只有指向該環境時才刪
link="$HOME/.local/bin/markitdown"
if [ -L "$link" ] && [ "$(readlink "$link")" = "$MD_VENV/bin/markitdown" ]; then
  rm -f "$link" && { t u_removed "$link"; echo; }
fi
[ -d "$MD_VENV" ] && rm -rf "$MD_VENV" && { t u_removed "$MD_VENV"; echo; }

if [ "$purge" -eq 1 ]; then
  if command -v uv >/dev/null 2>&1 && uv tool list 2>/dev/null | grep -q '^markitdown'; then
    uv tool uninstall markitdown
  fi
  if command -v pipx >/dev/null 2>&1 && pipx list --short 2>/dev/null | grep -q '^markitdown'; then
    pipx uninstall markitdown
  fi
elif command -v markitdown >/dev/null 2>&1; then
  t u_keep "$(command -v markitdown)" "$0"; echo
fi
t u_done; echo
