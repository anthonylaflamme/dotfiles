#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=false
SKIP_PACKAGES=false
BACKUP_DIR=""
DOTFILES=(.zshrc)

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Install the dotfiles and the selected command-line tools on macOS.

Options:
  --dry-run        Show the changes. Do not change files or install tools.
  --skip-packages  Install the dotfiles only.
  -h, --help       Show this help.
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

show_command() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
}

run() {
  if "$DRY_RUN"; then
    show_command "$@"
  else
    "$@"
  fi
}

parse_options() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      --skip-packages) SKIP_PACKAGES=true ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) fail "Unknown option: $1" ;;
    esac
    shift
  done
}

select_dotfiles() {
  local xdg_git_config="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"

  if [[ -n "${GIT_CONFIG_GLOBAL+x}" || -e "$HOME/.gitconfig" || -L "$HOME/.gitconfig" ||
        -e "$xdg_git_config" || -L "$xdg_git_config" ]]; then
    printf 'Keeping existing global Git configuration.\n'
  else
    DOTFILES+=(.gitconfig)
  fi
}

validate_dotfiles() {
  local name source target

  for name in "${DOTFILES[@]}"; do
    source="$SCRIPT_DIR/$name"
    target="$HOME/$name"
    [[ -f "$source" ]] || fail "Source file does not exist: $source"
    if [[ -d "$target" ]]; then
      fail "Target is a directory: $target"
    fi
  done
}

needs_copy() {
  local source=$1
  local target=$2

  [[ -L "$target" ]] && return 0
  [[ ! -e "$target" ]] || ! cmp -s "$source" "$target"
}

create_backup_dir() {
  local backup_root="$HOME/.dotfiles-backups"
  local timestamp

  [[ -z "$BACKUP_DIR" ]] || return 0
  timestamp="$(date +%Y%m%d-%H%M%S)"

  if "$DRY_RUN"; then
    BACKUP_DIR="$backup_root/$timestamp.XXXXXX"
    printf 'Would create backup directory: %s\n' "$BACKUP_DIR"
  else
    mkdir -p "$backup_root"
    BACKUP_DIR="$(mktemp -d "$backup_root/$timestamp.XXXXXX")"
    printf 'Backup directory: %s\n' "$BACKUP_DIR"
  fi
}

backup_dotfiles() {
  local name source target backup

  for name in "${DOTFILES[@]}"; do
    source="$SCRIPT_DIR/$name"
    target="$HOME/$name"
    needs_copy "$source" "$target" || continue
    [[ -e "$target" || -L "$target" ]] || continue

    create_backup_dir
    backup="$BACKUP_DIR/$name"
    [[ ! -e "$backup" && ! -L "$backup" ]] || fail "Backup already exists: $backup"
    if [[ -L "$target" ]]; then
      run ln -s "$(readlink "$target")" "$backup"
    else
      run cp -p "$target" "$backup"
    fi
  done
}

copy_dotfiles() {
  local name source target temporary

  for name in "${DOTFILES[@]}"; do
    source="$SCRIPT_DIR/$name"
    target="$HOME/$name"

    if ! needs_copy "$source" "$target"; then
      printf 'Unchanged: %s\n' "$target"
      continue
    fi
    if "$DRY_RUN"; then
      printf 'Would install: %s\n' "$target"
      continue
    fi

    temporary="$(mktemp "$HOME/.dotfiles-install.XXXXXX")"
    if ! cp -p "$source" "$temporary"; then
      rm -f "$temporary"
      fail "Cannot prepare: $target"
    fi
    if [[ "$name" == .gitconfig ]]; then
      if [[ -d "$target" ]] || ! ln -h "$temporary" "$target"; then
        rm -f "$temporary"
        fail "Cannot create Git configuration: $target"
      fi
      rm -f "$temporary"
    elif ! mv -f "$temporary" "$target"; then
      rm -f "$temporary"
      fail "Cannot install: $target"
    fi
    printf 'Installed: %s\n' "$target"
  done
}

find_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' /usr/local/bin/brew
  else
    return 1
  fi
}

install_packages() {
  local brew_bin
  local brew_installer='https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'
  local skip_bun=0

  if brew_bin="$(find_homebrew)"; then
    printf 'Homebrew is installed: %s\n' "$brew_bin"
  elif "$DRY_RUN"; then
    printf '+ /bin/bash -c "$(curl -fsSL %s)"\n' "$brew_installer"
    if [[ "$(uname -m)" == arm64 ]]; then
      brew_bin=/opt/homebrew/bin/brew
    else
      brew_bin=/usr/local/bin/brew
    fi
  else
    printf 'Installing Homebrew. Its installer can ask for confirmation.\n'
    /bin/bash -c "$(curl -fsSL "$brew_installer")"
    brew_bin="$(find_homebrew)" || fail 'Homebrew was installed, but brew was not found.'
  fi

  if ! "$DRY_RUN"; then
    eval "$("$brew_bin" shellenv)"
  fi

  if command -v bun >/dev/null 2>&1 || [[ -x "$HOME/.bun/bin/bun" ]]; then
    skip_bun=1
    printf 'Bun is already installed.\n'
  fi

  run env \
    DOTFILES_SKIP_BUN="$skip_bun" \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_BUNDLE_NO_UPGRADE=1 \
    HOMEBREW_NO_INSTALL_UPGRADE=1 \
    "$brew_bin" bundle --file="$SCRIPT_DIR/Brewfile" --no-upgrade
}

main() {
  parse_options "$@"
  [[ "$(uname -s)" == Darwin ]] || fail 'This installer supports macOS only.'
  select_dotfiles
  validate_dotfiles
  backup_dotfiles
  copy_dotfiles

  if "$SKIP_PACKAGES"; then
    printf 'Package installation skipped.\n'
  else
    install_packages
  fi
}

main "$@"
