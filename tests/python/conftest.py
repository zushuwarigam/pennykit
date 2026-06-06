import os
import pathlib
import shutil
import pytest

HERE = pathlib.Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent


@pytest.fixture
def pennykit_home(tmp_path):
    """Create a temporary pennykit home with minimal structure."""
    home = tmp_path / ".pennykit"
    home.mkdir()
    (home / "configs").mkdir()
    (home / "configs" / "themes").mkdir()
    (home / "scripts").mkdir()
    (home / "lib").mkdir()
    return home


@pytest.fixture
def theme_conf(pennykit_home):
    """Create a minimal theme config."""
    path = pennykit_home / "configs" / "themes" / "test_theme.conf"
    content = '''
PENNYKIT_THEME_NAME="test"
PENNYKIT_THEME_WEZTERM_LINUX="TestDark"
PENNYKIT_THEME_WEZTERM_MACOS="TestLight"
PENNYKIT_THEME_BAT="test-dark"
PENNYKIT_THEME_YAZI="test/yazi"
PENNYKIT_THEME_VIVID="test-dark"
PENNYKIT_THEME_HARLEQUIN="test"
PENNYKIT_THEME_NVIM="test-material"
PENNYKIT_THEME_LAZYGIT_BORDER="red"
PENNYKIT_THEME_TMUX="minimal"
PENNYKIT_THEME_OMB="duru"
PENNYKIT_THEME_OMZ="robbyrussell"
PENNYKIT_THEME_LF="32"
'''
    path.write_text(content)
    return path


@pytest.fixture
def mapping_toml(pennykit_home):
    """Create a minimal theme_mapping.toml."""
    path = pennykit_home / "configs" / "theme_mapping.toml"
    content = '''
[apps.wezterm]
file = "configs/wezterm/_local_theme.lua"
type = "template"
template = 'return { linux = "%WEZTERM_LINUX%", macos = "%WEZTERM_MACOS%" }'

[apps.nvim]
file = "configs/shared/nvim_colorscheme.lua"
type = "template"
template = 'return { colorscheme = "%NVIM%" }'
'''
    path.write_text(content)
    return path


@pytest.fixture
def pennykit_home_with_files(pennykit_home):
    """Create pennykit home with existing config files for sed operations."""
    wezterm_dir = pennykit_home / "configs" / "wezterm"
    wezterm_dir.mkdir(parents=True, exist_ok=True)
    (wezterm_dir / "_local_theme.lua").write_text("return { linux = '', macos = '' }\n")

    shared_dir = pennykit_home / "configs" / "shared"
    shared_dir.mkdir(parents=True, exist_ok=True)
    (shared_dir / "nvim_colorscheme.lua").write_text("return { colorscheme = '' }\n")

    theme_conf_dir = pennykit_home / "configs" / "themes"
    theme_conf_dir.mkdir(parents=True, exist_ok=True)
    (theme_conf_dir / "test_theme.conf").write_text('''
PENNYKIT_THEME_NAME="test"
PENNYKIT_THEME_WEZTERM_LINUX="CatppuccinMocha"
PENNYKIT_THEME_WEZTERM_MACOS="CatppuccinLatte"
PENNYKIT_THEME_BAT="Catppuccin-mocha"
PENNYKIT_THEME_YAZI="catppuccin-mocha"
PENNYKIT_THEME_VIVID="catppuccin-mocha"
PENNYKIT_THEME_HARLEQUIN="catppuccin-mocha"
PENNYKIT_THEME_NVIM="catppuccin-mocha"
PENNYKIT_THEME_LAZYGIT_BORDER="mauve"
PENNYKIT_THEME_TMUX="catppuccin"
PENNYKIT_THEME_OMB="powerline"
PENNYKIT_THEME_OMZ="powerlevel10k"
PENNYKIT_THEME_LF="32"
''')

    (pennykit_home / "configs" / "theme_mapping.toml").write_text('''
[apps.wezterm]
file = "configs/wezterm/_local_theme.lua"
type = "template"
template = 'return { linux = "%WEZTERM_LINUX%", macos = "%WEZTERM_MACOS%" }'

[apps.nvim]
file = "configs/shared/nvim_colorscheme.lua"
type = "template"
template = 'return { colorscheme = "%NVIM%" }'
''')

    return pennykit_home
