# Cursor configuration

`cursor/settings.json` and `cursor/keybindings.json` contain the shared settings and shortcuts. `cursor/extensions.txt` lists the extensions from the source Mac. Some extensions need a separate account or company access.

## Restore settings

1. Close Cursor.
2. Back up the files in `~/Library/Application Support/Cursor/User/` if they exist.
3. Copy `cursor/settings.json` and `cursor/keybindings.json` into that folder. Merge the files if you have settings or shortcuts to keep on this Mac.
4. Open Cursor. Check Settings Sync before you enable it. A sync service can replace the restored settings.

MonoLisa is the first choice for the editor font. Cursor can use Fira Code, Menlo, or the system monospace font when MonoLisa is absent.

## Restore extensions

Install the extensions you use on this Mac. The theme uses One Dark Pro (`zhuangtongfa.material-theme`). The icon theme uses Material Icon Theme (`pkief.material-icon-theme`). The default formatter is Prettier (`esbenp.prettier-vscode`).

To install the full list, enable the `cursor` command and run this from the repository root:

```sh
while IFS= read -r extension; do
    cursor --install-extension "$extension" || break
done < editors/cursor/extensions.txt
```

## Project and Mac settings

Select the Python interpreter in each project. The shared settings keep strict Cursor Pyright checks. Use project settings for lint fixes on save, type-aware linting, and formatter rules that differ from the shared defaults. Set up MCP servers on each Mac as needed.
