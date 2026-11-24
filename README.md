# Dotfiles

This repository sets up a Mac with Homebrew, Git, GitHub CLI, Bun, and Fira Code.
The installer does not upgrade installed packages. It does not install Node.js or iTerm2.

## Review the changes

Run a dry run from any directory:

```sh
/path/to/dotfiles/install.sh --dry-run
```

The dry run does not change files and does not run Homebrew or download packages.

## Install

Run:

```sh
/path/to/dotfiles/install.sh
```

The installer copies `.zshrc` to your home directory. If the file is different, the installer saves a copy under `~/.dotfiles-backups` first. The installer creates the starter `.gitconfig` only when you have no global Git configuration.

The installer uses paths relative to its own location. You can run it from a different directory. You can run it again. Files that already match are not copied again.

To install only the dotfiles, run:

```sh
/path/to/dotfiles/install.sh --skip-packages
```

On a new Mac, the Homebrew installer can ask for confirmation. The script loads `brew shellenv` only for the current installer process. It does not change `.zprofile`.

For Apple Silicon, add this line to `~/.zprofile` if it is not present:

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
```

For an Intel Mac, use this line:

```sh
eval "$(/usr/local/bin/brew shellenv)"
```

The Bun formula comes from Bun's official Homebrew tap. If `bun` is on `PATH`, or `~/.bun/bin/bun` exists, the installer keeps that Bun installation and skips the formula. The installer uses `brew bundle --no-upgrade` and disables Homebrew auto-update for the run.

## iTerm profile

`iterm/profile_2026.json` contains the exported profile with the fixed home path removed. The installer does not install iTerm2 or apply this profile.

The profile uses Fira Code Regular at 12 points. The installer includes the [Fira Code font](https://formulae.brew.sh/cask/font-fira-code).

The profile keeps directory mode `Recycle` (reuse the previous session directory). The unused fixed working directory was removed so the export does not contain a user-specific home path.

The profile is named `Default`. Review the imported profile before setting it as the default. The existing `theme.itermcolors` file is a separate color preset.

## Shell scope

The repository contains `.zshrc`. It does not contain `.zshenv` or `.zprofile`. The installer does not change those two files or uninstall software. Existing local setup in those files remains active.

The shell setup keeps the prompt, file colors, and paths for Bun, pnpm, and local tools. It uses `$HOME` and removes duplicate path entries. It initializes Zsh completion before loading the optional Bun completion file and registering npm and Yarn completion. These completion settings do not install npm, Yarn, or pnpm.

## Git identity

On a fresh Mac, set the name and email you use on that Mac.

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

The starter config tells Git to require an explicit identity. A Mac with an existing global config keeps its identity, credential helpers, and other Git settings. To require an explicit identity with an existing config, run `git config --global user.useConfigOnly true`.

If a repository needs a different identity, run `git config --local user.email "you@company.example"` from that repository. Set `user.name` there too if it differs. Use `git var GIT_AUTHOR_IDENT` to check the name and email Git will use.

## Cursor

Use the [Cursor restore guide](editors/README.md) to apply the shared settings and shortcuts. The installer leaves Cursor setup to you.
