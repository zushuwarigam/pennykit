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
