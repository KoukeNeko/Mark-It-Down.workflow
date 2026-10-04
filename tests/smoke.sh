#!/bin/bash
# 煙霧測試：以假的 markitdown/pbcopy/osascript 驗證轉換腳本的行為
# shellcheck disable=SC2016,SC2034  # check 的條件以單引號傳入 eval；rc 由 check 讀取
# 用法：tests/smoke.sh [bash|zsh]   （Quick Action 實際以 zsh 執行）
set -u
SH="${1:-bash}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
B="$T/bin"; mkdir -p "$B" "$T/home/Desktop" "$T/dir"
export HOME="$T/home" PATH="$B:$PATH"

cat >"$B/markitdown" <<'X'
#!/bin/sh
case "$1" in
  *bad*)   echo "UnsupportedFormatException: x" >&2; exit 1 ;;
  *dep*)   echo "No module named pdfminer" >&2; exit 1 ;;
  *empty*) exit 0 ;;
  *)       echo "# md of $(basename "$1")" ;;
esac
X
printf '#!/bin/sh\ncat >"%s/clip"\n' "$T" >"$B/pbcopy"
printf '#!/bin/sh\nfor a; do echo "$a"; done >>"%s/log"\nexit "${OSA_RC:-0}"\n' "$T" >"$B/osascript"
printf '#!/bin/sh\nexit 0\n' >"$B/open"
chmod +x "$B"/*
for n in ok.docx ok2.docx bad.pdf dep.pdf empty.pdf; do touch "$T/$n"; done

failed=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; failed=1; fi; }
run() {  # run <MODE> <檔案...>；結果碼放在 $rc
  local mode="$1"; shift; : >"$T/log"; : >"$T/clip"
  MODE="$mode" "$SH" -c 'lib=$1; main=$2; shift 2; source "$lib"; source "$main"' \
    _ "$ROOT/src/lib.sh" "$ROOT/src/mark-it-down.sh" "$@" >/dev/null 2>&1
  rc=$?
}

echo "== shell: $SH =="
run copy "$T/ok.docx"
check "copy: 單檔 rc=0 且進剪貼簿" '[ $rc -eq 0 ] && grep -q "# md of ok.docx" "$T/clip"'
check "copy: 單檔不加檔名分隔" '! grep -q "<!--" "$T/clip"'

run copy "$T/ok.docx" "$T/ok2.docx"
check "copy: 多檔以檔名分隔" 'grep -q "<!-- ok.docx -->" "$T/clip" && grep -q "<!-- ok2.docx -->" "$T/clip"'

run copy "$T/ok.docx" "$T/bad.pdf" "$T/dep.pdf" "$T/empty.pdf" "$T/dir" "$T/nope.txt"
check "copy: 混合時成功的仍複製、rc=0" '[ $rc -eq 0 ] && grep -q "# md of ok.docx" "$T/clip"'
check "copy: 彈窗列出 5 個失敗" 'grep -q "有 5 個檔案轉換失敗" "$T/log"'
check "copy: 失敗原因逐檔說明" 'grep -q "bad.pdf：不支援" "$T/log" && grep -q "dep.pdf：缺少轉換所需套件" "$T/log" && grep -q "empty.pdf：轉出內容為空" "$T/log" && grep -q "dir：是資料夾" "$T/log" && grep -q "nope.txt：無法讀取" "$T/log"'

run copy "$T/bad.pdf"
check "copy: 全部失敗 rc=1 且不動剪貼簿" '[ $rc -eq 1 ] && [ ! -s "$T/clip" ]'

run copy
check "無引數 rc=1" '[ $rc -eq 1 ] && grep -q "沒有選取任何檔案" "$T/log"'

rm -f "$T"/*.md
run file "$T/ok.docx"
check "file: 存成同名 .md" '[ $rc -eq 0 ] && [ -f "$T/ok.md" ]'
run file "$T/ok.docx"
check "file: 已存在時改為 -2" '[ -f "$T/ok-2.md" ] && [ "$(cat "$T/ok.md")" = "# md of ok.docx" ]'
run file "$T/ok.docx"
check "file: 再重複改為 -3" '[ -f "$T/ok-3.md" ]'

if [ "$(id -u)" != 0 ]; then
  mkdir -p "$T/ro"; touch "$T/ro/x.docx"; chmod 555 "$T/ro"
  run file "$T/ro/x.docx"
  check "file: 唯讀位置改存桌面" '[ $rc -eq 0 ] && [ -f "$HOME/Desktop/x.md" ]'
  chmod 755 "$T/ro"
fi

[ "$failed" -eq 0 ] && echo "ALL PASSED" || echo "SOME FAILED"
exit "$failed"
