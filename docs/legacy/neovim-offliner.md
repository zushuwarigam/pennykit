: <<"EOC"

# Get repo list
#:redir @a | :lua for _, p in pairs(require("lazy").plugins()) do print(p.url) end
#:put a

# Mirror repos
#!/bin/bash
set -euo pipefail

GITEA_URL="https://git.bme.local"
GITEA_TOKEN=""
LIST="$HOME/tmp/lazy.nvim_package.links"

while read -r clone_addr; do
  # Skip empty lines and comments
  [[ -z "$clone_addr" || "$clone_addr" == \#* ]] && continue

  # Extract "owner/repo" from URL, strip .git suffix
  repo="${clone_addr#https://github.com/}"
  repo="${repo%.git}"
  repo_name="$(echo "$repo" | tr '/' '-')"

  echo "Mirroring $repo -> $repo_name ..."

  HTTP_STATUS=$(curl -s -o /tmp/gitea_response.json -w "%{http_code}" \
    -X POST "$GITEA_URL/api/v1/repos/migrate" \
    -H "Authorization: token $GITEA_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"clone_addr\": \"$clone_addr\",
      \"mirror\": true,
      \"repo_name\": \"$repo_name\",
      \"repo_owner\": \"neovim-offliner\"
    }")

  if [ "$HTTP_STATUS" -eq 201 ]; then
    echo "  OK: $repo_name created"
  elif [ "$HTTP_STATUS" -eq 409 ]; then
    echo "  SKIP: $repo_name already exists"
  else
    echo "  ERROR ($HTTP_STATUS) for $repo_name:"
    cat /tmp/gitea_response.json
    echo
  fi
done < "$LIST"
EOC


: <<"EOC"
-- ~/.config/nvim/lua/config/lazy.lua
require("lazy").setup({
  spec = { import = "plugins" },
  git = {
    -- Rewrite all github.com URLs to your local Gitea
    url_format = "http://localhost:3000/youruser/%s.git",
  },
  checker = { enabled = false },
  install = { missing = false },
})

# Mason
#
# Option 1 — Pre-download and commit binaries
# After Mason installs everything online once:
# ls ~/.local/share/nvim/mason/bin/
# Copy the whole mason dir into your dotfiles repo
#
# Option 2 — Use mason-registry mirror
# git clone https://github.com/mason-org/mason-registry \
#  ~/my-mason-registry
#
# -- Tell Mason to use your local registry
# require("mason").setup({
#   registries = {
#     "file:~/my-mason-registry",
#   },
# })
# https://dev.to/ralphsebastian/masonnvim-the-ultimate-guide-to-managing-your-neovim-tooling-4520
#
EOC
