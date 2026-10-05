return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#0c1626",
        dark_bg = "#09111e",
        darker_bg = "#070c15",
        lighter_bg = "#17243a",

        fg = "#d8cbb4",
        dark_fg = "#9f9f9e",
        light_fg = "#e5dac5",
        bright_fg = "#f2e8d5",
        muted = "#5e6e87",

        red = "#db684c",
        yellow = "#d9a862",
        orange = "#dd8b57",
        green = "#93b56f",
        cyan = "#7fa8ab",
        blue = "#6e93bb",
        magenta = "#ab7fa8",
        brown = "#7a5e37",

        bright_red = "#e07a5f",
        bright_yellow = "#f0d4a0",
        bright_green = "#a8c48a",
        bright_cyan = "#a8ccce",
        bright_blue = "#8fb0d4",
        bright_magenta = "#c9a3c4",

        accent = "#d9a862",
        cursor = "#f2e8d5",
        foreground = "#d8cbb4",
        background = "#0c1626",
        selection = "#26364e",
        selection_foreground = "#f2e8d5",
        selection_background = "#26364e",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
