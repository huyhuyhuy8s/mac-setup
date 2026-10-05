return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    {
      "<leader>U",
      function()
        vim.cmd.UndotreeToggle()
      end,
      desc = "Toggle undotree",
    },
  },
}
