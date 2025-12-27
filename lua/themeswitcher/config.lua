local validator = require("themeswitcher.validator")

local theme_guide = {
	colorscheme = { required = true, types = { "string" } },
	name = { types = { "string" } },
	bg = { types = { "string" }, values = { "dark", "light" } },
	setup = { types = { "function" } },
	closure = { types = { "function" } },
}
local config = {}
local M = {
	guide = {
		themes = {
			default = {},
			types = { "table" },
			item_valid = {
				types = { "string", "table" },
				dict_valid = theme_guide,
			},
		},
		make_Color_cmd = { default = true, types = { "boolean" } },
		fallback = {
			default = "habamax",
			types = { "string", "table" },
			dict_valid = theme_guide,
		},
		fallback_setup = { default = nil, types = { "function" } },
		always_setup = { default = nil, types = { "function" } },
		fallback_closure = { default = nil, types = { "function" } },
		always_closure = { default = nil, types = { "function" } },
	},
}

local complete_theme = function(theme)
	if type(theme) == "string" then
		return { colorscheme = theme, name = theme, bg = nil, setup = nil, closure = nil }
	end
	local new = theme
	if type(theme) == "table" then
		if theme.name == nil then
			new["name"] = theme.colorscheme
			return new
		end
	end
	return new
end

local complete_themes = function()
	for i, x in ipairs(config.themes) do
		config.themes[i] = complete_theme(x)
	end
	config.fallback = complete_theme(config.fallback)
end

function M.set(opts)
	config = validator.parse_config(opts, M.guide)
	complete_themes()
end

function M.get()
	return config
end

return M
