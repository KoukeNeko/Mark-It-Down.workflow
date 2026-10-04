#!/bin/bash
# 依 tag 產生 Homebrew formula 並輸出到 stdout
# 用法：render-formula.sh <owner/repo> <tag>
set -euo pipefail
repo="${1:?owner/repo}"; tag="${2:?tag}"
here="$(cd "$(dirname "$0")" && pwd)"
url="https://github.com/$repo/archive/refs/tags/$tag.tar.gz"

sha=""
for _ in 1 2 3 4 5; do   # 剛建立的 release 偶爾要稍等才下載得到
  if sha="$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)" && [ -n "$sha" ]; then break; fi
  sleep 5
done
[ -n "$sha" ] || { echo "無法下載 $url" >&2; exit 1; }

sed -e "s|@REPO@|$repo|g" -e "s|@URL@|$url|g" -e "s|@SHA256@|$sha|g" \
  "$here/mark-it-down.rb.in"
