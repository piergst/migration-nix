return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = { -- Utilise`opts` pour surcharger la configuration existante
      filesystem = {
        window = {
          mappings = {
            ["/"] = "noop", -- Désactiver la recherche floue
          },
        },
        filtered_items = {
          visible = true, -- toujours montrer les fichiers cachés
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
    keys = {
      {
        "<leader>fE",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            dir = vim.fn.expand("%:p:h"),
            reveal = true,
          })
        end,
        desc = "Neo-tree (dir fichier courant, reveal)",
      },
    },
  },
}
