# 共用函式：尋找 / 安裝 markitdown（workflow 與 install.sh 共用）
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8" PYTHONIOENCODING="utf-8"

MD_PKG='markitdown[all]'
MD_VENV="$HOME/.local/share/markitdown-venv"

# 找一個可用的 Python >= 3.10（markitdown 的最低需求）；略過未裝 CLT 的 /usr/bin/python3 假殼
find_python() {
  local p path
  for p in python3.13 python3.12 python3.11 python3.10 python3; do
    path="$(command -v "$p" 2>/dev/null)" || continue
    if [ "$path" = /usr/bin/python3 ] && ! xcode-select -p >/dev/null 2>&1; then
      continue  # 呼叫它會跳出安裝 Xcode CLT 的視窗
    fi
    if "$path" -c 'import sys; sys.exit(sys.version_info < (3, 10))' 2>/dev/null; then
      echo "$path"; return 0
    fi
  done
  return 1
}

# 安裝 markitdown：uv > pipx > 自建 venv。成功回傳 0，失敗時把原因寫到 stderr
install_markitdown() {
  if command -v uv >/dev/null 2>&1; then
    uv tool install "$MD_PKG" && return 0
  elif command -v pipx >/dev/null 2>&1; then
    pipx install "$MD_PKG" && return 0
  fi
  local py
  if py="$(find_python)"; then
    mkdir -p "$HOME/.local/bin" \
      && "$py" -m venv "$MD_VENV" \
      && "$MD_VENV/bin/pip" install --quiet "$MD_PKG" \
      && ln -sf "$MD_VENV/bin/markitdown" "$HOME/.local/bin/markitdown" \
      && return 0
    echo "用 Python 建立環境安裝失敗（可能是網路問題）" >&2
    return 1
  fi
  echo "找不到 uv、pipx，也沒有 Python 3.10 以上。請先執行：brew install uv" >&2
  return 1
}
