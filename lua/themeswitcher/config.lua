local theme_guide = {
	colorscheme = { required = true, types = { "string" } },
	name = { types = { "string" } },
	bg = { types = { "string" }, values = { "dark", "light" } },
	setup = { types = { "function" } },
	closure = { types = { "function" } },
}

local M = {
	config_guide = {
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

function M.complete_themes_from_config(config)
	local new = config
	for i, x in ipairs(new.themes) do
		new.themes[i] = complete_theme(x)
	end
	new.fallback = complete_theme(new.fallback)
	return new
end

return M
