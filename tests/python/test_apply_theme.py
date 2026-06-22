import os
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent
APPLY_THEME = str(PROJECT_ROOT / "scripts" / "apply_theme.py")


def test_apply_theme_success(pennykit_home_with_files):
    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home_with_files)
    result = subprocess.run(
        ["python3", APPLY_THEME, "test_theme"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    assert "Theme" in result.stdout


def test_apply_theme_dry_run(pennykit_home_with_files):
    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home_with_files)
    result = subprocess.run(
        ["python3", APPLY_THEME, "test_theme", "--dry-run"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    assert "[DRY-RUN]" in result.stdout


def test_apply_theme_missing_theme(pennykit_home_with_files):
    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home_with_files)
    result = subprocess.run(
        ["python3", APPLY_THEME, "nonexistent"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode != 0


def test_apply_theme_writes_wezterm(pennykit_home_with_files):
    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home_with_files)
    result = subprocess.run(
        ["python3", APPLY_THEME, "test_theme"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    lua_file = pennykit_home_with_files / "configs" / "wezterm" / "_local_theme.lua"
    assert lua_file.exists()
    content = lua_file.read_text()
    assert "CatppuccinMocha" in content


def test_apply_theme_writes_theme_conf(pennykit_home_with_files):
    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home_with_files)
    result = subprocess.run(
        ["python3", APPLY_THEME, "test_theme"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    theme_conf = pennykit_home_with_files / "configs" / "theme.conf"
    assert theme_conf.exists()
    content = theme_conf.read_text()
    assert 'PENNYKIT_THEME="test_theme"' in content


# ── Edge cases ──────────────────────────────────────────────────

def test_apply_theme_missing_mapping_toml(pennykit_home):
    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home)
    result = subprocess.run(
        ["python3", APPLY_THEME, "test_theme"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode != 0
    assert "No such file" in result.stderr or "No such file" in result.stdout


def test_apply_theme_dry_run_does_not_modify_files(pennykit_home_with_files):
    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home_with_files)
    wezterm_file = pennykit_home_with_files / "configs" / "wezterm" / "_local_theme.lua"
    original = wezterm_file.read_text()
    result = subprocess.run(
        ["python3", APPLY_THEME, "test_theme", "--dry-run"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0
    assert wezterm_file.read_text() == original


def test_apply_theme_help_flag(pennykit_home_with_files):
    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home_with_files)
    result = subprocess.run(
        ["python3", APPLY_THEME, "--help"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0
    assert "Usage" in result.stdout
    assert "apply_theme.py" in result.stdout


# ── Theme with all app types ────────────────────────────────────

def test_apply_theme_all_app_types(pennykit_home):
    """Test that all operation types (sed, tmux_case, sed_or_append, sed_lf, post_cmd) work."""
    themes_dir = pennykit_home / "configs" / "themes"
    themes_dir.mkdir(parents=True, exist_ok=True)
    (themes_dir / "all_types.conf").write_text('''
PENNYKIT_THEME_NAME=all_types
PENNYKIT_THEME_BAT=test-dark
PENNYKIT_THEME_VIVID=test-dark
PENNYKIT_THEME_HARLEQUIN=test
PENNYKIT_THEME_LAZYGIT_BORDER=red
PENNYKIT_THEME_TMUX=minimal
PENNYKIT_THEME_OMB=duru
PENNYKIT_THEME_OMZ=robbyrussell
PENNYKIT_THEME_LF=32
PENNYKIT_THEME_YAZI=test/yazi
PENNYKIT_THEME_NVIM=test_nvim
PENNYKIT_THEME_WEZTERM_LINUX=dark
PENNYKIT_THEME_WEZTERM_MACOS=light
''')

    (pennykit_home / "configs" / "theme_mapping.toml").write_text('''
[apps.bat]
file = "configs/bat/config"
type = "sed"
search = '^--theme=".*"'
replace = '--theme="%BAT%"'
grep = '^--theme='

[apps.vivid]
file = "pennykit_shell.exports"
type = "sed"
search = "vivid generate .*"
replace = 'vivid generate %VIVID%)\\"'
grep = "vivid generate"

[apps.harlequin]
file = "pennykit_shell.alias"
type = "sed"
search = "--theme [a-zA-Z0-9_/-]*"
replace = "--theme %HARLEQUIN%"
grep = "--theme"

[apps.lazygit]
file = "configs/lazygit/config.yml"
type = "sed"
search = "activeBorderColor: \\\\[.*, bold\\\\]"
replace = "activeBorderColor: [%LAZYGIT_BORDER%, bold]"
grep = "activeBorderColor:"

[apps.tmux]
file = "configs/tmux/tmux_theme.conf"
type = "tmux_case"
variable = "TMUX"

[apps.shell_bash]
file = "{HOME}/.bashrc"
type = "sed"
search = '^OSH_THEME=".*"'
replace = 'OSH_THEME="%OMB%"'
grep = "^OSH_THEME="

[apps.shell_zsh]
file = "{HOME}/.zshrc"
type = "sed_or_append"
search = '^ZSH_THEME=".*"'
replace = 'ZSH_THEME="%OMZ%"'
append = 'ZSH_THEME="%OMZ%"'
grep = "^ZSH_THEME="

[apps.lf]
file = "configs/lf/lfrc"
type = "sed_lf"
grep = "set promptfmt"
variable = "LF"
''')

    bat_dir = pennykit_home / "configs" / "bat"
    bat_dir.mkdir(parents=True, exist_ok=True)
    (bat_dir / "config").write_text('--theme="default"\n')

    (pennykit_home / "pennykit_shell.exports").write_text(
        'export LS_COLORS="$(vivid generate default)"\n'
    )
    (pennykit_home / "pennykit_shell.alias").write_text(
        'alias hq="harlequin --theme default ."\n'
    )
    lazygit_dir = pennykit_home / "configs" / "lazygit"
    lazygit_dir.mkdir(parents=True, exist_ok=True)
    (lazygit_dir / "config.yml").write_text("activeBorderColor: [blue, bold]\n")

    tmux_dir = pennykit_home / "configs" / "tmux"
    tmux_dir.mkdir(parents=True, exist_ok=True)

    lf_dir = pennykit_home / "configs" / "lf"
    lf_dir.mkdir(parents=True, exist_ok=True)
    (lf_dir / "lfrc").write_text('set promptfmt "\\033[32m%u@%h\\033[0m:"\n')

    home_dir = pathlib.Path(os.environ.get("HOME", "/tmp"))
    bashrc = home_dir / ".bashrc"
    bashrc.write_text('OSH_THEME="default"\n')
    zshrc = home_dir / ".zshrc"
    zshrc.write_text('ZSH_THEME="default"\n')

    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home)
    result = subprocess.run(
        ["python3", APPLY_THEME, "all_types"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"

    assert '--theme="test-dark"' in (bat_dir / "config").read_text()
    assert "test-dark" in (pennykit_home / "pennykit_shell.exports").read_text()
    assert "test" in (pennykit_home / "pennykit_shell.alias").read_text()
    assert "red" in (lazygit_dir / "config.yml").read_text()
    assert "minimal" in (tmux_dir / "tmux_theme.conf").read_text()
    assert "duru" in bashrc.read_text()
    assert "robbyrussell" in zshrc.read_text()
    assert "32" in (lf_dir / "lfrc").read_text()


def test_apply_theme_sed_or_append_appends_when_no_match(pennykit_home):
    themes_dir = pennykit_home / "configs" / "themes"
    themes_dir.mkdir(parents=True, exist_ok=True)
    (themes_dir / "append_test.conf").write_text('''
PENNYKIT_THEME_OMZ="custom"
''')

    (pennykit_home / "configs" / "theme_mapping.toml").write_text('''
[apps.shell_zsh]
file = "{HOME}/.zshrc"
type = "sed_or_append"
search = '^ZSH_THEME=".*"'
replace = 'ZSH_THEME="%OMZ%"'
append = 'ZSH_THEME="%OMZ%"'
grep = "^ZSH_THEME="
''')

    home_dir = pathlib.Path(os.environ.get("HOME", "/tmp"))
    zshrc = home_dir / ".zshrc"
    zshrc.write_text("# no theme set\n")

    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home)
    result = subprocess.run(
        ["python3", APPLY_THEME, "append_test"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    assert 'ZSH_THEME="custom"' in zshrc.read_text()


def test_apply_theme_tmux_case_dracula(pennykit_home):
    themes_dir = pennykit_home / "configs" / "themes"
    themes_dir.mkdir(parents=True, exist_ok=True)
    (themes_dir / "dracula_test.conf").write_text('''
PENNYKIT_THEME_TMUX="dracula"
''')

    (pennykit_home / "configs" / "theme_mapping.toml").write_text('''
[apps.tmux]
file = "configs/tmux/tmux_theme.conf"
type = "tmux_case"
variable = "TMUX"
''')

    tmux_dir = pennykit_home / "configs" / "tmux"
    tmux_dir.mkdir(parents=True, exist_ok=True)

    env = os.environ.copy()
    env["PENNYKIT_HOME"] = str(pennykit_home)
    result = subprocess.run(
        ["python3", APPLY_THEME, "dracula_test"],
        capture_output=True, text=True, env=env
    )
    assert result.returncode == 0, f"stderr: {result.stderr}"
    content = (tmux_dir / "tmux_theme.conf").read_text()
    assert "dracula/tmux" in content
    assert "show-powerline" in content
