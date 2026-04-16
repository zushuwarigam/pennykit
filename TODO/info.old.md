# Bash start to play:
```
#!/usr/bin/env bash

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

```

# Use devcontainer
```
npm install -g @devcontainers/cli
devcontainer up --workspace-folder "$(pwd)"
devcontainer up --mount "type=bind,source=$HOME/.config/nvim,target=/home/vscode/.config/nvim" --workspace-folder .
devcontainer exec --workspace-folder "$(pwd)" -- bash
```

# Dev Gitea
# https://docs.gitea.com/development/hacking-on-gitea

# Build
```
TAGS="bindata sqlite sqlite_unlock_notify" make build
```

# Build for debug!
```
go build -o gitea-debug -gcflags="all=-N -l" main.go
```

# Run and watch
```
make watch
```
