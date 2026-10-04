# Mark It Down

在 macOS Finder 對檔案按右鍵 → 快速動作，用 [markitdown](https://github.com/microsoft/markitdown) 轉成 Markdown：

- **Mark It Down - 複製到剪貼簿**
- **Mark It Down - 存成 Markdown 檔**（在原檔旁存成 `.md`，已存在時改為 `-2`、`-3`…）

支援多選；完成會跳通知，失敗的檔案會逐一列出原因。

## 安裝

用 Homebrew：

```sh
brew install KoukeNeko/tap/mark-it-down
mark-it-down install
```

或直接從原始碼：

```sh
./install.sh
```

沒有 markitdown 時，安裝會自動補裝（`uv` > `pipx` > 自建 Python 虛擬環境）。
若右鍵選單沒出現：系統設定 → 鍵盤 → 鍵盤快速鍵 → 服務 → 檔案和資料夾。

## 移除

```sh
mark-it-down uninstall            # 只移除快速動作
mark-it-down uninstall --purge    # 連 markitdown 一併移除
brew uninstall mark-it-down
```

## 發版（維護者）

1. 更新 `VERSION`，commit。
2. `git tag v<版本>` 並推送 tag。
3. CI 會建立 GitHub release、產生 formula、以 Homebrew 驗證，並推送到 `KoukeNeko/homebrew-tap`。

需要在本 repo 設定 secret `HOMEBREW_TAP_TOKEN`（對 tap repo 有 Contents 寫入權限的 token）。

## 授權

MIT，詳見 [LICENSE](LICENSE)。
