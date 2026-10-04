# Mark It Down — 以 markitdown 將 Finder 選取的檔案轉成 Markdown
# MODE=copy：結果放進剪貼簿；MODE=file：在原檔旁存成 .md

notify() {
  osascript -e 'on run argv' \
            -e 'display notification (item 1 of argv) with title "Mark It Down"' \
            -e 'end run' "$1" >/dev/null 2>&1
}
alert() {  # alert 標題 內文
  osascript -e 'on run argv' \
            -e 'display alert (item 1 of argv) message (item 2 of argv) as warning' \
            -e 'end run' "$1" "$2" >/dev/null 2>&1
}
confirm_install() {
  osascript -e 'display alert "尚未安裝 markitdown" message "Mark It Down 需要 markitdown 才能轉換。要現在自動安裝嗎？（約需 1–3 分鐘，需要網路）" buttons {"取消", "自動安裝"} default button "自動安裝" cancel button "取消"' \
    >/dev/null 2>&1
}

if [ "$#" -eq 0 ]; then alert "沒有選取任何檔案" "請先在 Finder 選取檔案再執行。"; exit 1; fi

# --- 1. 確保 markitdown 可用 ---
if ! command -v markitdown >/dev/null 2>&1; then
  confirm_install || exit 1   # 使用者按取消
  notify "安裝 markitdown 中，請稍候…"
  if ! install_err="$(install_markitdown 2>&1 >/dev/null | tail -n 3)"; then
    alert "markitdown 安裝失敗" "$install_err"; exit 1
  fi
  hash -r
  command -v markitdown >/dev/null 2>&1 \
    || { alert "markitdown 安裝後仍找不到" "請開啟終端機執行 install.sh 查看詳細訊息。"; exit 1; }
  notify "markitdown 安裝完成，開始轉換"
fi

TMP="$(mktemp -d)" || { alert "無法建立暫存資料夾" "請檢查磁碟空間。"; exit 1; }
trap 'rm -rf "$TMP"' EXIT

# --- 2. 逐檔轉換 ---
ok=0; fail=0; failmsg=""; saved=""; fallback=0
add_fail() {  # add_fail 檔名 原因
  fail=$((fail + 1)); failmsg="$failmsg
• $1：$2"
}

for f in "$@"; do
  name="$(basename "$f")"
  if [ -d "$f" ]; then add_fail "$name" "是資料夾，僅支援檔案"; continue; fi
  if [ ! -r "$f" ]; then add_fail "$name" "無法讀取（不存在或沒有權限）"; continue; fi

  : >"$TMP/out.md"
  # 5 分鐘逾時，避免壞檔卡住
  if ! perl -e 'alarm 300; exec @ARGV' markitdown "$f" >"$TMP/out.md" 2>"$TMP/err.txt"; then
    err="$(grep -v '^\s*$' "$TMP/err.txt" | tail -n 1)"
    if grep -qiE 'MissingDependency|pip install|No module named' "$TMP/err.txt"; then
      err="缺少轉換所需套件，請重新安裝：pipx install --force 'markitdown[all]'"
    elif grep -qi 'UnsupportedFormat' "$TMP/err.txt"; then
      err="不支援的檔案格式"
    elif [ -z "$err" ]; then
      err="轉換逾時或異常中止"
    fi
    add_fail "$name" "$err"; continue
  fi
  if ! grep -q '[^[:space:]]' "$TMP/out.md"; then
    add_fail "$name" "轉出內容為空（可能是掃描檔或純圖片，沒有可擷取的文字）"; continue
  fi
  ok=$((ok + 1))

  if [ "$MODE" = "file" ]; then
    base="${f%.*}"; [ "$base" = "$f" ] && base="$f"
    dest="$base.md"; n=2
    while [ -e "$dest" ]; do dest="$base-$n.md"; n=$((n + 1)); done
    if ! cp "$TMP/out.md" "$dest" 2>/dev/null; then
      # 唯讀位置（光碟、唯讀磁碟、無權限）→ 退而存到桌面
      dest="$HOME/Desktop/$(basename "$base").md"; n=2
      while [ -e "$dest" ]; do dest="$HOME/Desktop/$(basename "$base")-$n.md"; n=$((n + 1)); done
      if cp "$TMP/out.md" "$dest" 2>/dev/null; then
        fallback=$((fallback + 1))
      else
        ok=$((ok - 1)); add_fail "$name" "無法寫入檔案（磁碟已滿或沒有權限）"; continue
      fi
    fi
    saved="$dest"
  else
    if [ "$#" -gt 1 ]; then printf '<!-- %s -->\n' "$name" >>"$TMP/all.md"; fi
    cat "$TMP/out.md" >>"$TMP/all.md"
    if [ "$#" -gt 1 ]; then printf '\n\n' >>"$TMP/all.md"; fi
  fi
done

# --- 3. 輸出與回報 ---
if [ "$MODE" != "file" ] && [ -s "$TMP/all.md" ]; then
  if ! pbcopy <"$TMP/all.md"; then
    alert "複製到剪貼簿失敗" "pbcopy 發生錯誤，請再試一次。"; exit 1
  fi
fi

if [ "$ok" -gt 0 ]; then
  if [ "$MODE" = "file" ]; then
    msg="已轉換 $ok 個檔案並存成 .md"
    [ "$ok" -eq 1 ] && msg="已存成 $(basename "$saved")"
    [ "$fallback" -gt 0 ] && msg="$msg（原位置不可寫入，已改存到桌面）"
    [ "$ok" -eq 1 ] && open -R "$saved" 2>/dev/null
  else
    msg="已複製到剪貼簿（$ok 個檔案）"
  fi
  notify "$msg"
fi
if [ "$fail" -gt 0 ]; then
  alert "有 $fail 個檔案轉換失敗" "$(printf '%s' "$failmsg" | sed '1{/^$/d;}' | head -n 6)"
fi
[ "$ok" -gt 0 ]
