return {
  "AckslD/nvim-neoclip.lua",
  dependencies = {
    { "nvim-telescope/telescope.nvim" },
    { "nvim-telescope/telescope-ui-select.nvim" },
  },
  config = function()
    require("neoclip").setup()
    require("telescope").load_extension("neoclip")
  end,
  keys = {
    {
      "<leader>p",
      function()
        local neoclip = require("telescope").extensions.neoclip
        local actions = require("telescope.actions")
        local state = require("telescope.actions.state")
        local action_set = require("telescope.actions.set")
        neoclip.default({
          attach_mappings = function(_, map)
            map("i", "<CR>", function(prompt_bufnr)
              local selection = state.get_selected_entry()
              if selection then
                local content = selection.value
                vim.fn.setreg('"', content)
                vim.api.nvim_put({ content }, "c", true, true)
              end
              actions.close(prompt_bufnr)
            end)
            map("n", "<CR>", function(prompt_bufnr)
              local selection = state.get_selected_entry()
              if selection then
                local content = selection.value
                vim.fn.setreg('"', content)
                vim.api.nvim_put({ content }, "c", true, true)
              end
              actions.close(prompt_bufnr)
            end)
            return true
          end,
        })
      end,
      desc = "Clipboard history",
    },
  },
}
