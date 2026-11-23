# config-nvim

## Introduction

*My personal Neovim configuration, based on [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim) — the multi-file fork of [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).*

A setup for Neovim that is:

- Small
- Modular
- Documented

It is built for my own environment — **Arch Linux + Hyprland + [end-4 dots](https://github.com/end-4/dots-hyprland) (illogical-impulse) + Kitty** — and keeps the editor visually consistent with the rest of the desktop by using the Matugen color palette generated from the current wallpaper.

Plugins are managed with the built-in `vim.pack`.

> [!NOTE]
> This is **not** a Neovim distribution. It is my personal config, published as a reference. Feel free to borrow anything from it.

## What is different from kickstart-modular

- **Dynamic colors instead of TokyoNight.** The editor palette is read at startup from the Matugen output used by end-4 dots (`~/.local/state/quickshell/user/generated/material_colors.scss`) and applied through `vim.api.nvim_set_hl()`. TokyoNight is disabled (its `require` is commented out in `lua/plugins.lua`).
- **Terminal colors.** `vim.g.terminal_color_0`–`15` are taken from `$term0`–`$term15`, so `:terminal` matches Kitty.
- **Transparent background.** `Normal` has no background fill, so Neovim shows the same background as the terminal.
- **Plugin highlights.** mini.statusline, Telescope, Which-key, Blink CMP, Gitsigns, Mason, Fidget and todo-comments are covered, along with Treesitter and LSP diagnostics.
- Everything else (options, keymaps, plugin set) follows kickstart-modular.

### Enabled plugins

`guess-indent`, `gitsigns`, `which-key`, `todo-comments`, `mini`, `telescope`, `lspconfig`, `conform`, `blink-cmp`, `treesitter` (see `lua/plugins.lua`).

### Color integration

The module lives in `lua/custom/plugins/colors.lua` and is required at the end of the plugin list in `lua/plugins.lua`, after all other plugins have loaded:

```lua
require 'custom.plugins.colors'
```

How it works:

- the palette is read **once at startup** — no file watchers, no Matugen calls from Neovim, no extra scripts;
- after changing the wallpaper, restart Neovim to pick up the new palette;
- if `material_colors.scss` is missing, unreadable or incomplete, Neovim still starts: a warning is shown via `vim.notify()` and the default colorscheme is used (or fallback colors for the missing values);
- colors are never hardcoded — everything comes from the generated file.

Requirements for this part: the end-4 dots setup (or any setup that generates the same `material_colors.scss` with `$background`, `$onBackground`, `$primary`, … and `$term0`–`$term15`). Without it the config still works, just with the default colorscheme.

## Installation

### Install Neovim

This config targets *only* the latest [stable](https://github.com/neovim/neovim/releases/tag/stable) and latest [nightly](https://github.com/neovim/neovim/releases/tag/nightly) Neovim, because it uses `vim.pack`.
To check your version, run `nvim --version`. Most likely you want to install Neovim via a [package manager](https://github.com/neovim/neovim/blob/master/INSTALL.md#install-from-package); if yours is outdated, see the [alternative installation methods](#alternative-neovim-installation-methods) below.

### Install External Dependencies

External Requirements:

- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`)
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation),
[fd-find](https://github.com/sharkdp/fd#installation)
- [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md#installation)
- Clipboard tool (xclip/xsel/wl-clipboard/win32yank or other depending on the platform)
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  * if you have it set `vim.g.have_nerd_font` in `init.lua` to true
- Language Setup:
  * If you want to write Typescript, you need `npm`
  * If you want to write Golang, you will need `go`
  * etc.
- For the dynamic colors: [Matugen](https://github.com/InioX/matugen) and end-4 dots (already configured to generate the palette)

> [!NOTE]
> See [Install Recipes](#install-recipes) for OS-specific notes and quick install snippets.

### Install the config

> [!NOTE]
> Back up your previous configuration (if any exists), see the [FAQ](#faq).

Neovim's configurations are located under the following paths, depending on your OS:

| OS                   | PATH                                      |
| -------------------- | ----------------------------------------- |
| Linux, MacOS         | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |
| Windows (cmd)        | `%localappdata%\nvim\`                    |
| Windows (powershell) | `$env:LOCALAPPDATA\nvim\`                 |

#### Clone config-nvim

**Linux and Mac**

```sh
git clone https://github.com/bdanil-main/config-nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

**Windows**

If you're using `cmd.exe`:

```
git clone https://github.com/bdanil-main/config-nvim.git "%localappdata%\nvim"
```

If you're using `powershell.exe`

```
git clone https://github.com/bdanil-main/config-nvim.git "${env:LOCALAPPDATA}\nvim"
```

### Post Installation

Start Neovim

```sh
nvim
```

That's it! `vim.pack` will install all the plugins from the config. Use `:lua vim.pack.update(nil, { offline = true })` to inspect plugin state and `:lua vim.pack.update()` to fetch updates (`:write` applies updates, `:quit` cancels them).

If you want to remove a plugin that is no longer loaded from disk (for example TokyoNight, which is disabled here), use:

```vim
:lua vim.pack.del({ 'tokyonight.nvim' })
```

#### Read The Friendly Documentation

Read through the `init.lua` and `lua/plugins.lua` files in your configuration folder for more information about extending and exploring Neovim, including examples of adding popular plugins.

> [!NOTE]
> For more information about a particular plugin check its repository's documentation.

### Getting Started

[The Only Video You Need to Get Started with Neovim](https://youtu.be/m8C0Cq9Uv9o)

### FAQ

- What should I do if I already have a pre-existing Neovim configuration?
  * You should back it up and then delete all associated files.
  * This includes your existing init.lua and the Neovim files in `~/.local` which can be deleted with `rm -rf ~/.local/share/nvim/`
- Can I keep my existing configuration in parallel to this one?
  * Yes! You can use [NVIM_APPNAME](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME)`=nvim-NAME` to maintain multiple configurations. For example, you can install this configuration in `~/.config/nvim-bdanil` and create an alias:

```sh
alias nvim-bdanil='NVIM_APPNAME="nvim-bdanil" nvim'
```

When you run Neovim using the `nvim-bdanil` alias it will use the alternative config directory and the matching local directory `~/.local/share/nvim-bdanil`. You can apply this approach to any Neovim distribution that you would like to try out.

- What if I want to "uninstall" this configuration?
  * Remove your config directory and local data directory (for example, `~/.config/nvim` and `~/.local/share/nvim`).
- Why is the init file split into multiple files?
  * The original kickstart keeps everything in a single `init.lua` as a teaching tool. This config is based on the modular fork, which keeps the same functionality split into smaller parts:
    + [kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)
  * The original repo with the single `init.lua` file is available here:
    + [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- Why does Neovim use the default colors / show a warning about the palette?
  * The palette file `~/.local/state/quickshell/user/generated/material_colors.scss` is missing, unreadable or incomplete. Check that end-4 dots has generated colors for the current wallpaper, then restart Neovim.

### Install Recipes

Below you can find OS specific install instructions for Neovim and dependencies.

After installing all the dependencies continue with the [Install the config](#install-the-config) step.

#### Linux Install

**Arch Install Steps** (the environment this config is built for)

```sh
sudo pacman -S --noconfirm --needed gcc make git ripgrep fd tree-sitter-cli unzip neovim wl-clipboard
```

**Ubuntu Install Steps**

```sh
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip neovim
```

**Debian Install Steps**

```sh
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip curl

# Now we install nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo mkdir -p /opt/nvim-linux-x86_64
sudo chmod a+rX /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# make it available in /usr/local/bin, distro installs to /usr/bin
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/
```

**Fedora Install Steps**

```sh
sudo dnf install -y gcc make git ripgrep fd-find tree-sitter-cli unzip neovim
```

**Alpine Install Steps**

> [!CAUTION]
> Neovim works fine on Alpine, but some tooling appears incompatible with musl
> (lua-language-server, etc., check `:Mason` or `:MasonLog`).
> Quickfix Lua-LSP-Support: `:%s/lua_ls/emmylua_ls`

```sh
sudo apk add gcc make git fd ripgrep tree-sitter-cli unzip bash gzip curl musl-dev neovim-doc neovim
```

#### Windows Installation

**Windows with gcc/make using chocolatey**

1. install [chocolatey](https://chocolatey.org/install) either follow the instructions on the page or use winget, run in cmd as **admin**:

```
winget install --accept-source-agreements chocolatey.chocolatey
```

2. install all requirements using choco, exit the previous cmd and open a new one so that choco path is set, and run in cmd as **admin**:

```
choco install -y neovim git ripgrep wget fd unzip gzip mingw make tree-sitter
```

**WSL (Windows Subsystem for Linux)**

```
wsl --install
wsl
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip neovim
```

> [!NOTE]
> The dynamic color integration relies on end-4 dots and is Linux-only; on other systems the config falls back to the default colorscheme.

### Alternative neovim installation methods

If your package manager ships an outdated Neovim, these methods deliver fresh versions quickly:

- [Bob](https://github.com/MordechaiHadad/bob) — Neovim version manager (`cargo install bob-nvim`, then `bob use stable`)
- [Homebrew](https://brew.sh) — `brew install neovim`
- [Flatpak](https://flathub.org/apps/io.neovim.nvim)
- [mise](https://mise.jdx.dev/) — `mise plugins install neovim && mise use neovim@stable`
- [asdf](https://asdf-vm.com/) — `asdf plugin add neovim && asdf install neovim stable && asdf set neovim stable --home`

## Credits

This configuration would not exist without:

- **[nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)** — the original, thoroughly documented starting point for Neovim. Huge thanks to its maintainers and contributors for a config that is small, readable and made for learning.
- **[dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)** — the multi-file fork that this config is built on. Thank you for the clean modular structure and for keeping it in sync with upstream.
- **[end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)** and **[Matugen](https://github.com/InioX/matugen)** — for the wallpaper-based palette that the editor colors come from.
- **[folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim)** — used as a reference for the structure of highlight groups.

## License

Kickstart is distributed under the MIT License; see [LICENSE.md](LICENSE.md). Keep the original license and copyright notices when reusing this config.
