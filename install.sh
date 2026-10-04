#!/bin/bash
# 安裝 Mark It Down 快速動作到 ~/Library/Services，並確保 markitdown 可用
set -uo pipefail
cd "$(dirname "$0")" || exit 1

[ "$(uname)" = Darwin ] || { echo "此工具僅支援 macOS" >&2; exit 1; }

# 建置到暫存資料夾，不在安裝來源（例如 Homebrew 的 keg）裡寫檔
DIST="$(mktemp -d)" || exit 1
trap 'rm -rf "$DIST"' EXIT
python3 build.py "$DIST" >/dev/null || { echo "建置失敗：需要 python3（請執行 xcode-select --install）" >&2; exit 1; }

mkdir -p "$HOME/Library/Services" || exit 1
for w in "$DIST"/*.workflow; do
  rm -rf "$HOME/Library/Services/$(basename "$w")"
  cp -R "$w" "$HOME/Library/Services/" || { echo "複製 $w 失敗" >&2; exit 1; }
  echo "installed: $(basename "$w")"
done
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

# shellcheck source=src/lib.sh
source src/lib.sh
if command -v markitdown >/dev/null 2>&1; then
  echo "markitdown 已安裝：$(command -v markitdown)"
else
  echo "安裝 markitdown..."
  install_markitdown || { echo "markitdown 安裝失敗，快速動作已安裝，但首次使用前請先手動安裝" >&2; exit 1; }
fi
echo "完成！Finder 檔案右鍵 → 快速動作 → Mark It Down"
echo "若選單沒出現：系統設定 → 鍵盤 → 鍵盤快速鍵 → 服務 → 檔案和資料夾"
