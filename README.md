<h1 align="center">themeswitcher.nvim </h1>
<p align="center"><sup>A colorscheme manager and switcher for Neovim (also my first and probably last Neovim plugin)</sup></p>


### Install
- For [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "uhhuhuhuhuh/themeswitcher.nvim",
    lazy = false,
    opts = {
        -- options here
    },
    keys = {
        -- keys here
    },
}

```
- For [packer.nvim](https://github.com/wbthomason/packer.nvim)
``` lua
use {
    "uhhuhuhuhuh/themeswitcher.nvim",
    config = function()
        require('themeswitcher').setup({
            -- options here
        })
        -- set keys using vim.keymap.set
    end
}
```

### How to use
#### Example
``` lua
require("themeswitcher").setup({
    themes = {
        "colorscheme1",
        "colorscheme2",
        {
            "colorscheme-which-uses-background",
            bg = "dark", -- no one likes light themed colorschemes
        },
        -- soft style for mycolors
        {
            colorscheme = "mycolors",
            name = "mycolors-soft",
            setup = function()
                require("mycolors").setup({ style = "soft" })
            end,
        },
        -- hard style for mycolors
        {
            colorscheme = "mycolors",
            name = "mycolors-hard",
            setup = function()
                require("mycolors").setup({ style = "hard" })
            end,
        },
    },
    make_Color_cmd = true, -- makes a custom command "Color" which uses the themes table for the aviable options
    fallback = "habamax",  -- fallback colorscheme, can only be a string, not a table
})

vim.keymap.set("n", "<C-L>", function()
    require("themeswitcher").next() -- Selects next theme
end, {desc = "Next theme"})
vim.keymap.set("n", "<C-H>", function()
    require("themeswitcher").prev() -- Selects prev theme
end, {desc = "Prev theme"})
```
#### Clarification on the theme format
##### String Format
``` lua
-- String provided is used as the name and colorscheme
"mycolorscheme"
```
##### Table Format
``` lua
{
    colorscheme = "mycolors", -- REQUIRED, used as the argument for vim.cmd.color()
    name = "mycolors-soft", -- Optional, used when referring to this theme, fallsback to colorscheme
    bg = "dark", -- Optional, used when assigning vim.o.background, MUST be either "dark" or "light"

    -- Optional, used to setup the colorscheme (in this case for a style), called before coloring
    setup = function()
        require("mycolors").setup({ style = "soft" })
    end,
}
```
#### API
``` lua
local ts = require("themeswitcher")

ts.set_theme("mythemename") -- sets a theme based off a name
ts.get_themes()             -- returns the themes table
ts.get_names()              -- returns the names of the items in the themes table
ts.next()                   -- applies next colorscheme
ts.prev()                   -- applies previous colorscheme
ts.setup({})                -- setups this plugin
```
#### How I used it
``` lua
local function onedark(style, bg)
    return {
        colorscheme = "onedark",
        name = bg ~= "light" and "onedark-" .. style or "onedark-" .. bg,
        bg = bg,
        setup = function()
            require("onedark").setup({ style = style })
        end,
    }
end
local function everforest(style, bg)
    return {
        colorscheme = "everforest",
        name = "everforest-" .. style .. "-" .. bg,
        bg = bg,
        setup = function()
            vim.g.everforest_background = style
        end,
    }
end
local function gruvbox(bg)
    return {
        colorscheme = "gruvbox",
        name = bg ~= "light" and "gruvbox-dark" or "gruvbox-light",
        bg = bg,
    }
end
local function oxocarbon(bg)
    return {
        colorscheme = "oxocarbon",
        name = bg ~= "light" and "oxocarbon-dark" or "oxocarbon-light",
        bg = bg,
    }
end

return {
    {
        "uhhuhuhuhuh/themeswitcher.nvim",
        lazy = false,
        opts = {
            themes = {
                "tokyonight-moon",
                "tokyonight-storm",
                "tokyonight-night",
                "tokyonight-day",
                "catppuccin-latte",
                "catppuccin-frappe",
                "catppuccin-macchiato",
                "catppuccin-mocha",
                "nightfox",
                "dayfox",
                "dawnfox",
                "duskfox",
                "nordfox",
                "terafox",
                "carbonfox",
                "kanagawa-wave",
                "kanagawa-dragon",
                "kanagawa-lotus",
                gruvbox("dark"),
                gruvbox("light"),
                onedark("dark", "dark"),
                onedark("darker", "dark"),
                onedark("cool", "dark"),
                onedark("deep", "dark"),
                onedark("warm", "dark"),
                onedark("warmer", "dark"),
                onedark("dark", "light"),
                everforest("medium", "dark"),
                everforest("hard", "dark"),
                everforest("medium", "light"),
                everforest("hard", "light"),
                "rose-pine-main",
                "rose-pine-moon",
                "rose-pine-dawn",
                "jellybeans",
                "ayu-dark",
                "ayu-mirage",
                "ayu-light",
                oxocarbon("dark"),
                oxocarbon("light"),
            },
            fallback = "habamax",
        },
        keys = {
            {
                "<C-l>",
                function()
                    require("themeswitcher").next()
                end,
                desc = "Select next theme",
            },
            {
                "<C-h>",
                function()
                    require("themeswitcher").prev()
                end,
                desc = "Select prev theme",
            },
        },
    },
    { "folke/tokyonight.nvim", priority = 1000 },
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    { "EdenEast/nightfox.nvim", priority = 1000 },
    { "rebelot/kanagawa.nvim", priority = 1000 },
    { "ellisonleao/gruvbox.nvim", priority = 1000 },
    { "navarasu/onedark.nvim", priority = 1000 },
    { "sainnhe/everforest", priority = 1000 },
    { "rose-pine/neovim", name = "rose-pine", priority = 1000 },
    { "nanotech/jellybeans.vim", priority = 1000 },
    { "Shatur/neovim-ayu", priority = 1000 },
    { "nyoom-engineering/oxocarbon.nvim", priority = 1000 },
}
```
### Why?
I made a copy of my neovim config which I used to test plugins and colorscheme so I needed something to easily switch between colorschemes and their style.
<sub><sup>I got bored too...</sup></sub>
