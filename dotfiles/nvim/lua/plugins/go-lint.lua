return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      local root = vim.fs.root(0, { "go.mod" })
      if root then
        opts.linters = opts.linters or {}
        opts.linters.golangcilint = {
          append_fname = false,
          cwd = root,
          cmd = "golangci-lint",
          args = {
            "run",
            "--output.json.path=stdout",
            "--output.text.path=",
            "--output.tab.path=",
            "--output.html.path=",
            "--output.checkstyle.path=",
            "--output.code-climate.path=",
            "--output.junit-xml.path=",
            "--output.teamcity.path=",
            "--output.sarif.path=",
            "--issues-exit-code=0",
            "--show-stats=false",
            "--path-mode=abs",
          },
        }
      end
    end,
  },
}
