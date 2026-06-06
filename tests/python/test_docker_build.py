import subprocess
import pytest


@pytest.mark.slow
def test_docker_build_apt_os_stage():
    """Verify Dockerfile.apt builds the 'os' stage successfully."""
    result = subprocess.run(
        ["docker", "build", "--target", "os", "-f", "Dockerfile.apt", "."],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"docker build failed:\n{result.stderr}"


@pytest.mark.slow
def test_docker_build_brew_os_stage():
    """Verify Dockerfile.brew builds the 'os' stage successfully."""
    result = subprocess.run(
        ["docker", "build", "--target", "os", "-f", "Dockerfile.brew", "."],
        capture_output=True, text=True
    )
    assert result.returncode == 0, f"docker build failed:\n{result.stderr}"
