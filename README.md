# Mark It Down

**English** | [繁體中文](README.zh-TW.md)

Right-click files in macOS Finder → Quick Actions to convert them to Markdown with [markitdown](https://github.com/microsoft/markitdown):

- **Mark It Down - Copy to Clipboard**
- **Mark It Down - Save as Markdown File** (saved next to the original as `.md`; an existing file gets `-2`, `-3`, … instead of being overwritten)

Multiple selection is supported. A notification appears when done, and any file that fails is listed with its reason.
Notifications and menu names follow your system language (English or Traditional Chinese).

## Install

With Homebrew:

```sh
brew install KoukeNeko/tap/mark-it-down
mark-it-down install
```

Or from source:

```sh
./install.sh
```

If markitdown is missing, the installer sets it up for you (`uv` > `pipx` > a private Python virtual environment).
Pick a language with `--lang en` or `--lang zh` (default: system language).
If the menu does not appear: System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders.

## Uninstall

```sh
mark-it-down uninstall            # remove the Quick Actions only
mark-it-down uninstall --purge    # also remove markitdown
brew uninstall mark-it-down
```

## License

MIT. See [LICENSE](LICENSE).
