return {
  {
    "lazy.nvim",
    opts = {
      git = {
        url_format = function(repo)
          return "https://git.bme.loca/neovim-offliner/" .. repo:gsub("/", "-") .. ".git"
        end,
      },
    },
  },
}
