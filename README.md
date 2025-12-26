<h1 align="center">themeswitcher.nvim </h1>
<p align="center"><sup>A colorscheme manager and switcher for Neovim (also my first and probably last Neovim plugin)</sup></p>


### Install
- For [lazy.nvim](https://github.com/folke/lazy.nvim)
``` lua
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
            colorscheme = "colorscheme-which-uses-background",
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
    make_Color_cmd = true,  -- makes a custom command "Color" which uses the themes table for the aviable options
    fallback = "habamax",   -- fallback theme, same syntax as themes' items'
    fallback_setup = nil,   -- fallback setup if there is none provided for a theme
    always_setup = nil,     -- setup function called for every theme, called after setup
    fallback_closure = nil, -- fallback closure if there is none provided for a theme
    always_closure = nil,   -- closure function called for every theme (called after coloring)
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
"mycolors"
```
##### Table Format
``` lua
{
    colorscheme = "mycolors", -- REQUIRED, used as the argument for vim.cmd.color()
    name = "mycolors-soft", -- Optional, used when referring to this theme, fallsback to colorscheme
    bg = "dark", -- Optional, used when assigning vim.o.background, MUST be either "dark" or "light"

    -- Optional, used to setup the colorscheme, called before coloring
    setup = function()
        -- set style beforehand
        require("mycolors").setup({ style = "soft" })
    end,
    -- Optional, used after coloring of the theme
    closure = function()
        -- set transparent bg after
        vim.api.nvim_set_hl(0, "Normal", { bg = "None" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "None" })
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
### Why?
I made a copy of my neovim config which I used to test plugins and colorscheme so I needed something to easily switch between colorschemes and their style.
<sub><sup>I got bored too...</sup></sub>
