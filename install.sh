#!/usr/bin/env bash
#
# install.sh — install my Neovim config (macOS + Linux)
#
#   ./install.sh                 copy the config into ~/.config/nvim, install
#                                plugins, then only the tree-sitter parsers
#                                that are missing
#   ./install.sh --link          symlink back to this folder instead of copying
#   ./install.sh --deps          install missing tools (brew / apt / dnf / pacman / zypper / apk / rustup)
#   ./install.sh --skip-plugins  leave plugins alone
#   ./install.sh --skip-parsers  leave tree-sitter parsers alone
#
# Environment variables (isolated profiles, testing):
#   NVIM_APPNAME      isolated nvim profile (default "nvim"): nvim will use
#                     ~/.config/<name> and ~/.local/share/<name>
#   NVIM_CONFIG_DIR   override the config target
#   NVIM_DATA_DIR     override the data directory
#   SUDO              command used for system packages (default: sudo, if needed)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPNAME="${NVIM_APPNAME:-nvim}"
export NVIM_APPNAME="$APPNAME"
DEST="${NVIM_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/$APPNAME}"
DATA="${NVIM_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/$APPNAME}"
PARSER_DIR="$DATA/site/parser"

MODE=copy
INSTALL_DEPS=0
DO_PLUGINS=1
DO_PARSERS=1
PARSERS="bash c comment cpp css diff dockerfile git_rebase gitcommit gitignore go html javascript json lua make markdown markdown_inline python query regex rust toml tsx typescript vim vimdoc yaml"

# --- platform -------------------------------------------------------------
case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux)  OS=linux ;;
    *)      OS=unknown ;;
esac

PKG=""
if [ "$OS" = macos ]; then
    candidates="brew"
else
    candidates="apt-get dnf pacman zypper apk"
fi
for m in $candidates; do
    if command -v "$m" >/dev/null 2>&1; then PKG="$m"; break; fi
done
# fall back to whatever exists if the platform-specific list came up empty
if [ -z "$PKG" ]; then
    for m in brew apt-get dnf pacman zypper apk; do
        if command -v "$m" >/dev/null 2>&1; then PKG="$m"; break; fi
    done
fi

# sudo, only when the package manager needs it
SUDO_CMD="${SUDO:-}"
if [ -z "$SUDO_CMD" ] && [ "$(id -u)" != 0 ]; then
    command -v sudo >/dev/null 2>&1 && SUDO_CMD=sudo
fi

pkg_install() {   # pkg_install <brew-name> <generic-name>
    case "$PKG" in
        brew)    brew install "$1" ;;
        apt-get) $SUDO_CMD apt-get install -y "$2" ;;
        dnf)     $SUDO_CMD dnf install -y "$2" ;;
        pacman)  $SUDO_CMD pacman -S --noconfirm "$2" ;;
        zypper)  $SUDO_CMD zypper install -y "$2" ;;
        apk)     $SUDO_CMD apk add "$2" ;;
        *)       return 1 ;;
    esac
}

usage() {
    sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
    case "$arg" in
        --link)          MODE=link ;;
        --deps)          INSTALL_DEPS=1 ;;
        --skip-plugins)  DO_PLUGINS=0 ;;
        --skip-parsers)  DO_PARSERS=0 ;;
        -h|--help)       usage; exit 0 ;;
        *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

ok()   { printf '\342\234\224 %s\n' "$*"; }
warn() { printf '\342\232\240 %s\n' "$*"; }
die()  { printf '\342\234\230 %s\n' "$*" >&2; exit 1; }

echo "Neovim config — install"
echo "  source   : $SRC"
echo "  target   : $DEST"
echo "  platform : $OS${PKG:+ (packages via $PKG)}"
echo

# 1. neovim ---------------------------------------------------------------
if ! command -v nvim >/dev/null 2>&1; then
    echo "nvim not found. Install Neovim 0.11 or newer:"
    case "$OS" in
        macos) echo "    brew install neovim" ;;
        linux) echo "    Debian/Ubuntu : the distro package is often too old — use the AppImage or the"
               echo "                    tarball from https://github.com/neovim/neovim/releases, or the"
               echo "                    'unstable' PPA / snap"
               echo "    Fedora        : sudo dnf install neovim"
               echo "    Arch          : sudo pacman -S neovim" ;;
        *)     echo "    https://github.com/neovim/neovim/releases" ;;
    esac
    die "install Neovim first"
fi
NVIM_HEAD="$(nvim --version | head -1)"
case "$NVIM_HEAD" in
    *v0.11*|*v0.12*|*v0.13*|*v0.14*|*v0.15*) ok "nvim: $NVIM_HEAD" ;;
    *) warn "this config targets nvim 0.11+ (tested on 0.12.5) — found: $NVIM_HEAD"
       warn "upgrade before expecting the LSP and winbar features to behave" ;;
esac

# 2. external dependencies ------------------------------------------------
missing=""
for c in tree-sitter rg rust-analyzer clangd; do
    command -v "$c" >/dev/null 2>&1 || missing="$missing $c"
done

if [ -n "$missing" ]; then
    warn "missing tools:$missing"
    echo "     tree-sitter   tree-sitter parsers (nvim-treesitter)"
    echo "     rg            text search (telescope)"
    echo "     rust-analyzer Rust LSP (rustup component add rust-analyzer)"
    echo "     clangd        C/C++ LSP (optional outside C projects)"
    if [ "$INSTALL_DEPS" = 1 ]; then
        if ! command -v tree-sitter >/dev/null 2>&1; then
            if pkg_install tree-sitter tree-sitter-cli; then ok "tree-sitter CLI installed"
            elif command -v cargo >/dev/null 2>&1; then
                echo "  cargo install tree-sitter-cli"; cargo install tree-sitter-cli
            else
                warn "install the tree-sitter CLI by hand (cargo install tree-sitter-cli)"
            fi
        fi
        if ! command -v rg >/dev/null 2>&1; then
            if pkg_install ripgrep ripgrep; then ok "ripgrep installed"
            else warn "install ripgrep with your package manager"; fi
        fi
        if ! command -v rust-analyzer >/dev/null 2>&1; then
            if command -v rustup >/dev/null 2>&1; then
                echo "  rustup component add rust-analyzer"; rustup component add rust-analyzer
            else
                warn "rustup not found: Rust LSP unavailable"
            fi
        fi
        if ! command -v clangd >/dev/null 2>&1 && [ "$OS" = linux ]; then
            if pkg_install clangd clangd; then ok "clangd installed"
            else warn "install clangd for the C/C++ LSP, or drop clangd from the config"; fi
        fi
        ok "dependency pass done"
    else
        warn "re-run with --deps to install them automatically"
    fi
else
    ok "external tools present (tree-sitter, rg, rust-analyzer, clangd)"
fi

# clipboard: opt.clipboard = "unnamedplus" needs a provider on Linux
if [ "$OS" = linux ]; then
    if command -v wl-copy >/dev/null 2>&1 || command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1; then
        ok "clipboard provider found"
    else
        warn "no clipboard tool: install wl-clipboard (Wayland) or xclip (X11) for system yanks"
    fi
fi

# 3. back up the existing config ------------------------------------------
if [ -e "$DEST" ]; then
    BACKUP="$DEST.bak.$(date +%s)"
    cp -R "$DEST" "$BACKUP"
    ok "existing config backed up to $BACKUP"
fi
mkdir -p "$DEST"

# 4. config files ---------------------------------------------------------
if [ "$MODE" = link ]; then
    ln -sf "$SRC/init.lua" "$DEST/init.lua"
    ln -sf "$SRC/lazy-lock.json" "$DEST/lazy-lock.json"
    ok "symlinks created (you edit here, nvim reads there)"
else
    cp "$SRC/init.lua" "$DEST/init.lua"
    cp "$SRC/lazy-lock.json" "$DEST/lazy-lock.json"
    ok "init.lua and lazy-lock.json installed"
fi

# 5. plugins (lazy.nvim follows lazy-lock.json) ----------------------------
if [ "$DO_PLUGINS" = 1 ]; then
    echo "  installing plugins (lazy.nvim)..."
    nvim --headless "+Lazy! sync" +qa 2>&1 | tail -3 || warn "lazy sync reported an error"
    ok "plugins installed"
fi

# 6. tree-sitter parsers — ONLY the missing ones --------------------------
# (the config deliberately never kicks off a parser build at startup)
if [ "$DO_PARSERS" = 1 ]; then
    pmissing=""
    for p in $PARSERS; do
        [ -f "$PARSER_DIR/$p.so" ] || pmissing="$pmissing \"$p\","
    done
    if [ -n "$pmissing" ]; then
        pmissing="${pmissing%,}"
        echo "  missing parsers:$pmissing"
        nvim --headless -c "lua require('nvim-treesitter').install({ $pmissing })" \
            -c "sleep 180" -c "qa!" || warn "parser installation incomplete"
        ok "parsers installed into $PARSER_DIR"
    else
        ok "all 28 tree-sitter parsers already present"
    fi
fi

# 7. verification ---------------------------------------------------------
# With no plugins installed, launching nvim would trigger their download: only
# check that the config loads once the setup is complete.
if [ ! -d "$DATA/lazy/lazy.nvim" ]; then
    warn "no plugins in $DATA: startup check skipped (just launch nvim)"
elif nvim --headless +qa >/dev/null 2>&1; then
    ok "config loads with no error (profile \"$APPNAME\")"
else
    die "config fails to load — run 'nvim' to see the message"
fi

cat <<'NOTES'

Done.

Worth knowing:
  • A Nerd Font is required for the tree and file icons (tuned on JetBrainsMono Nerd
    Font). Without one you get boxes instead of glyphs.
  • The terminal's own settings do not travel with this repo: the cursor shape and the
    background transparency come from the terminal profile/emulator, not from nvim.
  • Add a language: `:TSInstall <lang>`, then add it to PARSERS in this script.
  • Re-running this script is safe: dated backup, then copy.
NOTES