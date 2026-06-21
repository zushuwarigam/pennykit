# Docker Install Test Script — Design

## Goal

A robust bash script that runs the full Pennykit Docker build (multi-stage: os → pkgs → nvim → runtime) with real-time log analysis, capturing layer timing and package install timestamps.

## Requirements

- Docker requires `sudo` — all docker commands prefixed with `sudo`
- Long-running build (apt pkgs + nvim Lazy install) — `timeout` guard, 2h default
- Real-time log viewing + capture — `tee` to terminal + file
- Log analysis: build progress/errors, package install timing

## Location

`scripts/test_docker_install.sh` — next to existing `build_docker-image.sh`

## Pipeline

```
sudo docker build --progress=plain -f Dockerfile.apt -t pennykit:test .
  → ts '[%Y-%m-%d %H:%M:%S]'  (optional, moreutils)
  → tee logs/build-{timestamp}.log
  → post-build grep-based analysis
  → logs/build-{timestamp}.summary
```

## Script Sections

### 1. Setup
- Parse `SCRIPT_DIR` / `PROJECT_DIR`
- `mkdir -p logs/`
- `TIMESTAMP=$(date +%Y%m%d_%H%M%S)`
- `LOG_FILE="logs/docker-install-$TIMESTAMP.log"`, `SUMMARY_FILE="logs/docker-install-$TIMESTAMP.summary"`
- Detect `ts` (moreutils); fallback to `cat` if missing

### 2. Build
```bash
timeout ${BUILD_TIMEOUT:-7200} \
  sudo docker build --progress=plain -f Dockerfile.apt -t pennykit:test . 2>&1 \
  | "$TIMESTAMPER" \
  | tee "$LOG_FILE"
BUILD_EXIT=${PIPESTATUS[0]}
```

### 3. Post-build analysis (grep-based)
Extract from `$LOG_FILE` into `$SUMMARY_FILE`:

| Section | Pattern |
|---|---|
| Layer timing | `#\d+ DONE \d+\.\d+s` |
| Package install | `apt-get install\|apt install` + following packages |
| Errors | `[Ee]rror` (max 20 lines) |
| Warnings | `[Ww]arning` (max 20 lines) |
| Lazy install | `Lazy[ :]\|Lazy\.locked\|plugins` + context |
| Total duration | `head -1` timestamp vs `tail -1` timestamp |

### 4. Exit
- Print `$SUMMARY_FILE` path
- Exit with `$BUILD_EXIT`

## Dependencies

- **Required:** `sudo`, `docker`, `coreutils` (timeout)
- **Optional:** `moreutils` (ts) — script works without it

## Example Output

```
=== Pennykit Docker Install Test ===
Log: logs/docker-install-20260621_143022.log

[...build output streams live...]

=== Build Summary ===
Exit code: 0
Status: SUCCESS

--- Layer Timing ---
#1 DONE 0.0s
#5 DONE 45.2s

--- Package Install Timing ---
2026-06-21 14:30:22 apt-get install -y --no-install-recommends bat fd-find ...

--- Errors ---
(none)

--- Total Build Time ---
Start: 2026-06-21 14:30:22
End:   2026-06-21 14:38:47
Summary saved to: logs/docker-install-20260621_143022.summary
```
