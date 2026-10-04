#!/bin/bash
# 依 tag 產生 Homebrew cask 並輸出到 stdout（會下載 release 上的 zip 計算 sha256）
# 用法：render-cask.sh <owner/repo> <tag>
set -euo pipefail
repo="${1:?owner/repo}"; tag="${2:?tag}"
here="$(cd "$(dirname "$0")" && pwd)"
version="${tag#v}"
url="https://github.com/$repo/releases/download/$tag/Mark-It-Down-$version.zip"

sha=""
for _ in 1 2 3 4 5; do   # 剛上傳的 asset 偶爾要稍等才下載得到
  if sha="$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)" && [ -n "$sha" ]; then break; fi
  sleep 5
done
[ -n "$sha" ] || { echo "無法下載 $url" >&2; exit 1; }

sed -e "s|@REPO@|$repo|g" -e "s|@VERSION@|$version|g" -e "s|@SHA256@|$sha|g" \
  "$here/mark-it-down.cask.in"
