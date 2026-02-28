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
        -- dark theme
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
        -- group of colorschemes
        {
            name = "builtin",
            themes = {
                -- default's complete path is "builtin/default"
                "default"
                "habamax",
            }
        }
    },
    make_Color_cmd = true,  -- make a command, "Color" which uses the themes table
    Themes_cmd = {          -- configuration around command, "Themes"
        make = true,            -- make the command
        live_preview = true,    -- preview the theme under the cursor
    },
    fallback = "habamax",          -- fallback theme, same syntax as themes' items'
    fallback_setup = nil,          -- fallback setup if there is none provided for a theme
    always_setup = nil,            -- setup function called for every theme, called after setup
    fallback_closure = nil,        -- fallback closure if there is none provided for a theme
    always_closure = nil,          -- closure function called for every theme (called after coloring)
    join_symbol = "/",             -- the join symbol used when building a path when using theme groups
    groups_open_by_default = false -- if true then when opening the UI groups will be open by default
})

vim.keymap.set("n", "<C-L>", function()
    require("themeswitcher").next() -- Selects next theme
end, { desc = "Next theme" })
vim.keymap.set("n", "<C-H>", function()
    require("themeswitcher").prev() -- Selects prev theme
end, { desc = "Prev theme" })
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
    colorscheme = "mycolors", -- REQUIRED, the argument for vim.cmd.color()
    name = "mycolors-soft",   -- the string used to refer to this theme
    bg = "dark",              -- vim.o.background's value, either "dark" or "light"

    -- Used to setup the colorscheme, called before coloring
    setup = function()
        -- set style beforehand
        require("mycolors").setup({ style = "soft" })
    end,
    -- Used after coloring of the theme
    closure = function()
        -- set transparent bg after
        vim.api.nvim_set_hl(0, "Normal", { bg = "None" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "None" })
    end,
}
```
##### Theme Groups
``` lua
{
    name = "mygroup" -- REQUIRED used for the group name
    themes = {       -- REQUIRED the themes the group contains
        "my-really-cool-colors",
        {
            colorscheme = "my-great-table-colors",
            bg = "dark",
        },
        {
            name = "my-sub-group",
            themes = {
                "my-other-colors",
            },
        },
    },
}
```
#### API
``` lua
local ts = require("themeswitcher")

ts.set_theme("mythemename") -- sets a theme based off a path
ts.set_theme_idx(1)         -- sets a theme based off an idx
ts.get_themes()             -- returns the themes table
ts.get_paths()              -- returns the paths of the themes and theme groups
ts.get_theme_paths()        -- returns the paths of only the themes
ts.open_window()            -- opens the themeswitcher.nvim UI
ts.close_window()           -- closes the themeswitcher.nvim UI
ts.next()                   -- applies next colorscheme
ts.prev()                   -- applies previous colorscheme
ts.setup({})                -- sets up this plugin
```
### Why?
I made a copy of my neovim config which I used to test plugins and colorschemes so I needed something to easily switch
between colorschemes and their styles.
<sub><sup>I got bored too...</sup></sub>

### Things to note
- I used [themery.nvim](https://github.com/zaldih/themery.nvim) to understand how windows and buffers worked in vim, also my
  plugin is pretty similiar to theirs (not that there are many ways to make a colorscheme manager)
- ~~To test vibe coding I used deepseek to make a highly general and complete 
  [configuration validator](https://github.com/uhhuhuhuhuh/themeswitcher.nvim/blob/2b6b478d75c9ebb33cadb8519a368a6ac618c058/lua/themeswitcher/validator.lua)
  , [config guide here](https://github.com/uhhuhuhuhuh/themeswitcher.nvim/blob/2b6b478d75c9ebb33cadb8519a368a6ac618c058/lua/themeswitcher/config.lua)~~
  I decided it was easier to add features to a config validator which is not overly general however I have took things from
  the old validator into my new one put in [config.lua](https://github.com/uhhuhuhuhuh/themeswitcher.nvim/blob/main/lua/themeswitcher/config.lua).
