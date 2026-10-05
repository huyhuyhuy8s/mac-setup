return {
  "nvim-telescope/telescope-file-browser.nvim",
  keys = {
    {
      "<leader>s0",
      ":Telescope file_browser path=%:p:h=%:p:h<cr>",
      desc = "Browser Files",
    },
  },
  opts = {
    hidden = true,
  },
  config = function(_, opts)
    require("telescope").setup({ extensions = { file_browser = opts } })
    require("telescope").load_extension("file_browser")
  end,
}
