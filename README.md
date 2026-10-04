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
brew install --cask KoukeNeko/tap/mark-it-down
```

Or from source:

```sh
./install.sh
```

If markitdown is missing, you are asked on first use and it is installed for you (`uv` > `pipx` > a private Python virtual environment).
The Homebrew version uses English menu names; installing from source lets you pick with `--lang en` or `--lang zh` (default: system language).
If the menu does not appear: System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders.

## Uninstall

```sh
brew uninstall --cask mark-it-down
```

If installed from source:

```sh
./uninstall.sh            # remove the Quick Actions only
./uninstall.sh --purge    # also remove markitdown
```

## License

MIT. See [LICENSE](LICENSE).
