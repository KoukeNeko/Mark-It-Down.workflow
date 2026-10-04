#!/bin/bash
# 依 tag 產生 Homebrew cask 並輸出到 stdout（會下載 release 上的 zip 計算 sha256）
# 用法：render-cask.sh <owner/repo> <tag>
set -euo pipefail
repo="${1:?owner/repo}"; tag="${2:?tag}"
here="$(cd "$(dirname "$0")" && pwd)"
version="${tag#v}"
url="https://github.com/$repo/releases/download/$tag/Mark-It-Down-$version.zip"

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
ok=0
for _ in 1 2 3 4 5; do   # 剛上傳的 asset 偶爾要稍等才下載得到
  if curl -fsSL -o "$tmp" "$url" && [ -s "$tmp" ]; then ok=1; break; fi
  sleep 5
done
# 先下載成檔案再算雜湊：下載失敗時不會算出「空字串」的雜湊而蒙混過關
[ "$ok" -eq 1 ] || { echo "無法下載 $url（release 是否仍是草稿？）" >&2; exit 1; }
sha="$(shasum -a 256 "$tmp" | cut -d' ' -f1)"

sed -e "s|@REPO@|$repo|g" -e "s|@VERSION@|$version|g" -e "s|@SHA256@|$sha|g" \
  "$here/mark-it-down.cask.in"
