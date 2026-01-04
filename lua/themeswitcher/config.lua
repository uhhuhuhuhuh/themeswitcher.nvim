local config = {}
local M = {}

local getcleanedsimpleopt = function(key, opts, types, values, default, path, required)
	required = required ~= nil and required or false
	if path ~= "" then
		path = type(key) == "number" and path .. "[" .. tostring(key) .. "]" or path .. "." .. key
	else
		path = key
	end
	if opts[key] == nil then
		if required == true then
			vim.notify(path .. " is required", "ERROR")
		end
		return default
	end

	local keytype = type(opts[key])
	local isin = false
	for _, type in ipairs(types) do
		if keytype == type then
			isin = true
			break
		end
	end
	if not isin then
		vim.notify(path .. " has wrong type: " .. keytype, "ERROR")
		return default
	end

	if #values > 0 then
		isin = false
		for _, value in ipairs(values) do
			if opts[key] == value then
				isin = true
			end
		end
		if not isin then
			vim.notify(path .. " has wrong value: " .. opts[key], "ERROR")
			return default
		end
	end

	return opts[key]
end

local getcleanedtheme = function(theme, path)
	local new = theme
	new["colorscheme"] = getcleanedsimpleopt("colorscheme", new, { "string" }, {}, "default", path, true)
	new["name"] = getcleanedsimpleopt("name", new, { "string" }, {}, new.colorscheme, path)
	new["bg"] = getcleanedsimpleopt("bg", new, { "string" }, { "dark", "light" }, nil, path)
	new["setup"] = getcleanedsimpleopt("setup", new, { "function" }, {}, nil, path)
	new["closure"] = getcleanedsimpleopt("closure", new, { "function" }, {}, nil, path)
	return new
end
local cleanthemes
cleanthemes = function(themes, path)
	for i, t in ipairs(themes) do
		if type(i) ~= "number" then
			goto continue
		end

		local errname = "error " .. tostring(i)
		themes[i] = getcleanedsimpleopt(
			i,
			themes,
			{ "table", "string" },
			{},
			{ colorscheme = "default", name = errname },
			path
		)
		if type(themes[i]) == "string" then
			themes[i] = { colorscheme = t, name = t }
			goto continue
		end

		local ipath = path .. "[" .. tostring(i) .. "]"
		if themes[i].themes == nil then
			themes[i] = getcleanedtheme(themes[i], ipath)
			goto continue
		end

		-- Group of themes
		-- themes[i].name = getcleanedsimpleopt("name", themes[i], { "string" }, {}, errname, ipath, true)
		-- cleanthemes(themes[i].themes, ipath .. ".themes")

		::continue::
	end
end

local getcleanedThemes_cmd = function(themescmd, path)
	local new = themescmd
	new["make"] = getcleanedsimpleopt("make", new, { "boolean" }, {}, true, path)
	new["live_preview"] = getcleanedsimpleopt("live_preview", new, { "boolean" }, {}, true, path)
	return new
end

local getcleaned = function(opts)
	local cleaned = {}
	local path = ""
	cleaned["themes"] = getcleanedsimpleopt("themes", opts, { "table" }, {}, {}, path)
	cleanthemes(cleaned.themes, "themes")
	cleaned["fallback"] = getcleanedsimpleopt("fallback", opts, { "table", "string" }, {}, "habamax", path)
	if type(cleaned.fallback) == "table" then
		cleaned.fallback = getcleanedtheme(cleaned.fallback, "fallback")
	else
		cleaned.fallback = { colorscheme = cleaned.fallback, name = cleaned.fallback }
	end
	cleaned["fallback_setup"] = getcleanedsimpleopt("fallback_setup", opts, { "function" }, {}, nil, path)
	cleaned["always_setup"] = getcleanedsimpleopt("always_setup", opts, { "function" }, {}, nil, path)
	cleaned["fallback_closer"] = getcleanedsimpleopt("fallback_closer", opts, { "function" }, {}, nil, path)
	cleaned["always_closure"] = getcleanedsimpleopt("always_closure", opts, { "function" }, {}, nil, path)
	cleaned["make_Color_cmd"] = getcleanedsimpleopt("make_Color_cmd", opts, { "boolean" }, {}, true, path)
	cleaned["make_Debugthemesprint_cmd"] = getcleanedsimpleopt(
		"make_Debugthemesprint_cmd",
		opts,
		{ "boolean" },
		{},
		false,
		path
	)
	cleaned["Themes_cmd"] = getcleanedsimpleopt("Themes_cmd", opts, { "table" }, {}, {
		make = true,
		live_preview = true,
	}, path)
	cleaned["Themes_cmd"] = getcleanedThemes_cmd(cleaned["Themes_cmd"], "Themes_cmd")

	return cleaned
end

local themesarrtodict = function(config)
	config.names = {}
	for i, t in ipairs(config.themes) do
		config.themes[t.name] = { colorscheme = t.colorscheme, bg = t.bg, setup = t.setup, closure = t.closure }
		config.names[i] = t.name
		config.themes[i] = nil
	end
end

function M.set(opts)
	config = getcleaned(opts)
	themesarrtodict(config)
end

function M.get()
	return config
end

return M
