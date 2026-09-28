return {
  "TobinPalmer/pastify.nvim",
  cmd = { "Pastify", "PastifyAfter" },
  config = function()
    require("pastify").setup({
      opts = {
        -- Following options "absolute_path", "save" and "local_file" are
        -- configured to make images saved in a folder named with the same name
        -- as the edited file (without extension) created in the the same
        -- directory as the edited file. Final image path is absolute path.
        absolute_path = true,
        save = "local_file",
        local_path = function()
          return vim.fn.expand("%:t:r")
        end, -- Get the file name without extension
      },
    })
  end,
}
