# Pennykit

A comprehensive, opinionated development environment setup tool that automates the installation and configuration of a professional development environment.

## Installation

### Quick Install

```bash
bash <(curl -ks https://raw.githubusercontent.com/zushuwarigam/pennykit/refs/heads/kit/install)
```

### Manual Installation

```bash
git clone https://github.com/zushuwarigam/pennykit.git ~/.pennykit
cd ~/.pennykit
./install
```

## Features

### Shell Configuration

- **Aliases**: Git shortcuts, Docker management, file operations, and more
- **Functions**: Note-taking, directory management, server hosting, and backup utilities
- **Custom bindings**: Search and open files in Neovim with `Ctrl+F`
- **Environment setup**: Custom paths, editor preferences, and theme customization

### Package Management

Automated installation across multiple platforms:

- **APT (Debian/Ubuntu)**: Default, admin, dev, and pentest package sets
- **Homebrew (macOS)**: Package management for macOS systems
- **Package types**: npm, pipx, and external packages

### Tool Configuration

Automated setup for:
- **Neovim**: Interactive configuration with multiple starter themes
- **Terminal tools**: bat, fzf, lf, tmux, lazygit, wezterm, yazi, and more
- **Documentation**: Glow markdown renderer, Git enhancements
- **System utilities**: File managers, search tools, and monitoring utilities

### Key Tools Included

- **Git**: Enhanced status, logging, and staging
- **File Management**: eza/lsd, lf/yazi, fd, ripgrep
- **Editors**: Neovim with ZenMode support
- **Terminal**: tmux, wezterm
- **System Monitoring**: glances, nethogs, btm
- **Documentation**: Glow markdown renderer
- **Development**: Rust, Node.js, Python, Go toolchains

## Package Sets

- **Default**: Essential tools for daily development
- **Admin**: Administrative utilities and system tools
- **Dev**: Development tools and compilers
- **Pentest**: Security testing tools
- **ALL**: All of the above packages

## Usage

After installation, your shell configuration will be loaded automatically. You can access the package installer with:

```bash
./scripts/package_installer.sh [apt|brew] [package_set]
```

For example:

```bash
./scripts/package_installer.sh apt dev
```

## Documentation Tools

- `note` - Create or edit notes with `note <description>`
- `note -l` - List existing notes with fzf
- `note -d` - Edit timesheets for the current date
- `glow` - Render Markdown beautifully in terminal

## Shell Customization

The system supports both Bash and Zsh with the following key features:

- `Ctrl+F` - Search codebase and open in Neovim
- `Ctrl+E` - Edit and execute current command
- `Ctrl+L` - Clear screen

## Customization

- **Neovim**: Run `pennykit.sh` or `pk` to select a configuration
- **Shell**: Edit `pennykit_shell.*` files in `~/.pennykit/`
- **Packages**: Modify `packages/apt.*`, `packages/npm.*`, etc.

## License

MIT License - See LICENSE file for details