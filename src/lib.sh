# 共用函式：語系、尋找 / 安裝 markitdown（workflow 與各 shell 指令共用）
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
export LC_ALL="en_US.UTF-8" LANG="en_US.UTF-8" PYTHONIOENCODING="utf-8"

# ---- 語系：MD_LANG=en|zh 可強制指定，否則依系統偏好語言（中文系 → zh，其餘 en）----
detect_lang() {
  local l="${MD_LANG:-}"
  if [ -z "$l" ]; then
    l="$(defaults read -g AppleLanguages 2>/dev/null | sed -n '2p' | tr -d ' ",')"
  fi
  case "$l" in zh*) echo zh ;; *) echo en ;; esac
}
MD_L="$(detect_lang)"

_t_en() {
  local f
  case "$1" in
    sep) f=': ' ;;
    no_sel_title) f='No files selected' ;;
    no_sel_body) f='Select files in Finder first, then run it again.' ;;
    need_title) f='markitdown is not installed' ;;
    need_body) f='Mark It Down needs markitdown to convert files. Install it now? (about 1–3 minutes, network required)' ;;
    btn_cancel) f='Cancel' ;;
    btn_install) f='Install' ;;
    installing) f='Installing markitdown, please wait…' ;;
    install_fail_title) f='Failed to install markitdown' ;;
    install_missing_title) f='markitdown still not found after installing' ;;
    install_missing_body) f='Run install.sh in Terminal to see the details.' ;;
    install_done) f='markitdown installed, converting…' ;;
    tmp_title) f='Cannot create a temporary folder' ;;
    tmp_body) f='Please check your disk space.' ;;
    r_dir) f='is a folder; only files are supported' ;;
    r_unreadable) f='cannot be read (missing or no permission)' ;;
    r_dep) f="missing conversion packages; reinstall with: pipx install --force 'markitdown[all]'" ;;
    r_unsupported) f='unsupported file format' ;;
    r_timeout) f='conversion timed out or aborted' ;;
    r_empty) f='the output is empty (a scanned or image-only file has no extractable text)' ;;
    r_write) f='cannot write the file (disk full or no permission)' ;;
    ok_saved1) f='Saved as %s' ;;
    ok_savedn) f='Converted %s files and saved as .md' ;;
    ok_fallback) f=' (location not writable, saved to Desktop instead)' ;;
    ok_copied) f='Copied to clipboard (%s file(s))' ;;
    fail_title) f='%s file(s) failed to convert' ;;
    clip_title) f='Failed to copy to the clipboard' ;;
    clip_body) f='pbcopy reported an error. Please try again.' ;;
    err_venv) f='Installing into a Python environment failed (possibly a network problem)' ;;
    err_notool) f='Found no uv, no pipx and no Python 3.10+. Run first: brew install uv' ;;
    i_macos_only) f='This tool only supports macOS' ;;
    i_build_fail) f='Build failed: python3 is required (run xcode-select --install)' ;;
    i_copy_fail) f='Failed to copy %s' ;;
    i_installed) f='installed: %s' ;;
    i_md_have) f='markitdown already installed: %s' ;;
    i_md_installing) f='Installing markitdown...' ;;
    i_md_fail) f='markitdown installation failed. The Quick Actions are installed, but install markitdown manually before first use' ;;
    i_done) f='Done! In Finder: right-click a file → Quick Actions → Mark It Down' ;;
    i_hint) f='If the menu does not appear: System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders' ;;
    u_usage) f='Usage: %s [--purge] [--lang en|zh]' ;;
    u_removed) f='removed: %s' ;;
    u_none) f='No installed Quick Actions found (maybe already removed)' ;;
    u_keep) f='Keeping markitdown (%s); to remove it as well run: %s --purge' ;;
    u_done) f='Done!' ;;
    *) f="$1" ;;
  esac
  printf '%s' "$f"
}

_t_zh() {
  local f
  case "$1" in
    sep) f='：' ;;
    no_sel_title) f='沒有選取任何檔案' ;;
    no_sel_body) f='請先在 Finder 選取檔案再執行。' ;;
    need_title) f='尚未安裝 markitdown' ;;
    need_body) f='Mark It Down 需要 markitdown 才能轉換。要現在自動安裝嗎？（約需 1–3 分鐘，需要網路）' ;;
    btn_cancel) f='取消' ;;
    btn_install) f='自動安裝' ;;
    installing) f='安裝 markitdown 中，請稍候…' ;;
    install_fail_title) f='markitdown 安裝失敗' ;;
    install_missing_title) f='markitdown 安裝後仍找不到' ;;
    install_missing_body) f='請開啟終端機執行 install.sh 查看詳細訊息。' ;;
    install_done) f='markitdown 安裝完成，開始轉換' ;;
    tmp_title) f='無法建立暫存資料夾' ;;
    tmp_body) f='請檢查磁碟空間。' ;;
    r_dir) f='是資料夾，僅支援檔案' ;;
    r_unreadable) f='無法讀取（不存在或沒有權限）' ;;
    r_dep) f="缺少轉換所需套件，請重新安裝：pipx install --force 'markitdown[all]'" ;;
    r_unsupported) f='不支援的檔案格式' ;;
    r_timeout) f='轉換逾時或異常中止' ;;
    r_empty) f='轉出內容為空（可能是掃描檔或純圖片，沒有可擷取的文字）' ;;
    r_write) f='無法寫入檔案（磁碟已滿或沒有權限）' ;;
    ok_saved1) f='已存成 %s' ;;
    ok_savedn) f='已轉換 %s 個檔案並存成 .md' ;;
    ok_fallback) f='（原位置不可寫入，已改存到桌面）' ;;
    ok_copied) f='已複製到剪貼簿（%s 個檔案）' ;;
    fail_title) f='有 %s 個檔案轉換失敗' ;;
    clip_title) f='複製到剪貼簿失敗' ;;
    clip_body) f='pbcopy 發生錯誤，請再試一次。' ;;
    err_venv) f='用 Python 建立環境安裝失敗（可能是網路問題）' ;;
    err_notool) f='找不到 uv、pipx，也沒有 Python 3.10 以上。請先執行：brew install uv' ;;
    i_macos_only) f='此工具僅支援 macOS' ;;
    i_build_fail) f='建置失敗：需要 python3（請執行 xcode-select --install）' ;;
    i_copy_fail) f='複製 %s 失敗' ;;
    i_installed) f='已安裝：%s' ;;
    i_md_have) f='markitdown 已安裝：%s' ;;
    i_md_installing) f='安裝 markitdown...' ;;
    i_md_fail) f='markitdown 安裝失敗，快速動作已安裝，但首次使用前請先手動安裝' ;;
    i_done) f='完成！Finder 檔案右鍵 → 快速動作 → Mark It Down' ;;
    i_hint) f='若選單沒出現：系統設定 → 鍵盤 → 鍵盤快速鍵 → 服務 → 檔案和資料夾' ;;
    u_usage) f='用法：%s [--purge] [--lang en|zh]' ;;
    u_removed) f='已移除：%s' ;;
    u_none) f='找不到已安裝的快速動作（可能已經移除）' ;;
    u_keep) f='保留 markitdown（%s）；要一併移除請執行：%s --purge' ;;
    u_done) f='完成！' ;;
    *) f="$1" ;;
  esac
  printf '%s' "$f"
}

# t KEY [參數...]：依目前語系輸出訊息（printf 格式）
t() {
  local key="$1" fmt; shift
  if [ "$MD_L" = zh ]; then fmt="$(_t_zh "$key")"; else fmt="$(_t_en "$key")"; fi
  # shellcheck disable=SC2059
  printf "$fmt" "$@"
}

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
    t err_venv >&2; echo >&2
    return 1
  fi
  t err_notool >&2; echo >&2
  return 1
}
