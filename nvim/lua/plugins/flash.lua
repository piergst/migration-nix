return {
  "folke/flash.nvim",
  keys = {
    -- Remplacer 's' par 'm' pour la fonction flash.jump()
    {
      "m",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump()
      end,
      desc = "Flash",
    },
    -- disable the default flash keymap
    { "s", mode = { "n", "x", "o" }, false },
  },
}
