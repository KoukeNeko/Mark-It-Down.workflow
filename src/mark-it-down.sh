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
  osascript -e 'on run argv' \
            -e 'display alert (item 1 of argv) message (item 2 of argv) buttons {item 3 of argv, item 4 of argv} default button (item 4 of argv) cancel button (item 3 of argv)' \
            -e 'end run' "$(t need_title)" "$(t need_body)" "$(t btn_cancel)" "$(t btn_install)" >/dev/null 2>&1
}

if [ "$#" -eq 0 ]; then alert "$(t no_sel_title)" "$(t no_sel_body)"; exit 1; fi

# --- 1. 確保 markitdown 可用 ---
if ! command -v markitdown >/dev/null 2>&1; then
  confirm_install || exit 1   # 使用者按取消
  notify "$(t installing)"
  if ! install_err="$(install_markitdown 2>&1 >/dev/null | tail -n 3)"; then
    alert "$(t install_fail_title)" "$install_err"; exit 1
  fi
  hash -r
  command -v markitdown >/dev/null 2>&1 \
    || { alert "$(t install_missing_title)" "$(t install_missing_body)"; exit 1; }
  notify "$(t install_done)"
fi

TMP="$(mktemp -d)" || { alert "$(t tmp_title)" "$(t tmp_body)"; exit 1; }
trap 'rm -rf "$TMP"' EXIT

# --- 2. 逐檔轉換 ---
ok=0; fail=0; failmsg=""; saved=""; fallback=0
add_fail() {  # add_fail 檔名 原因
  fail=$((fail + 1)); failmsg="$failmsg
• $1$(t sep)$2"
}

for f in "$@"; do
  name="$(basename "$f")"
  if [ -d "$f" ]; then add_fail "$name" "$(t r_dir)"; continue; fi
  if [ ! -r "$f" ]; then add_fail "$name" "$(t r_unreadable)"; continue; fi

  : >"$TMP/out.md"
  # 5 分鐘逾時，避免壞檔卡住
  if ! perl -e 'alarm 300; exec @ARGV' markitdown "$f" >"$TMP/out.md" 2>"$TMP/err.txt"; then
    err="$(grep -v '^\s*$' "$TMP/err.txt" | tail -n 1)"
    if grep -qiE 'MissingDependency|pip install|No module named' "$TMP/err.txt"; then
      err="$(t r_dep)"
    elif grep -qi 'UnsupportedFormat' "$TMP/err.txt"; then
      err="$(t r_unsupported)"
    elif [ -z "$err" ]; then
      err="$(t r_timeout)"
    fi
    add_fail "$name" "$err"; continue
  fi
  if ! grep -q '[^[:space:]]' "$TMP/out.md"; then
    add_fail "$name" "$(t r_empty)"; continue
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
        ok=$((ok - 1)); add_fail "$name" "$(t r_write)"; continue
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
    alert "$(t clip_title)" "$(t clip_body)"; exit 1
  fi
fi

if [ "$ok" -gt 0 ]; then
  if [ "$MODE" = "file" ]; then
    msg="$(t ok_savedn "$ok")"
    [ "$ok" -eq 1 ] && msg="$(t ok_saved1 "$(basename "$saved")")"
    [ "$fallback" -gt 0 ] && msg="$msg$(t ok_fallback)"
    [ "$ok" -eq 1 ] && open -R "$saved" 2>/dev/null
  else
    msg="$(t ok_copied "$ok")"
  fi
  notify "$msg"
fi
if [ "$fail" -gt 0 ]; then
  alert "$(t fail_title "$fail")" "$(printf '%s' "$failmsg" | sed '1{/^$/d;}' | head -n 6)"
fi
[ "$ok" -gt 0 ]
