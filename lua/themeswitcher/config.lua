local config = {}
local M = {}

local cleansimpleopt = function(key, opts, types, values, default, path, required)
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
	new["colorscheme"] = cleansimpleopt("colorscheme", new, { "string" }, {}, "default", path, true)
	new["name"] = cleansimpleopt("name", new, { "string" }, {}, new.colorscheme, path)
	new["bg"] = cleansimpleopt("bg", new, { "string" }, { "dark", "light" }, nil, path)
	new["setup"] = cleansimpleopt("setup", new, { "function" }, {}, nil, path)
	new["closure"] = cleansimpleopt("closure", new, { "function" }, {}, nil, path)
	return new
end

local getcleanedThemes_cmd = function(themescmd, path)
	local new = themescmd
	new["make"] = cleansimpleopt("make", new, { "boolean" }, {}, true, path)
	new["live_preview"] = cleansimpleopt("live_preview", new, { "boolean" }, {}, true, path)
	return new
end

local getcleaned = function(opts)
	local cleaned = {}
	local path = ""
	cleaned["themes"] = cleansimpleopt("themes", opts, { "table" }, {}, {}, path)
	for i, t in ipairs(cleaned.themes) do
		if type(i) ~= "number" then
			goto continue
		end
		cleaned.themes[i] = cleansimpleopt(
			i,
			opts["themes"],
			{ "table", "string" },
			{},
			{ colorscheme = "default", name = "error " .. tostring(i) },
			"themes"
		)
		if type(cleaned.themes[i]) == "string" then
			cleaned.themes[i] = { colorscheme = t, name = t }
		else
			cleaned.themes[i] = getcleanedtheme(cleaned.themes[i], "themes[" .. tostring(i) .. "]")
		end

		::continue::
	end
	cleaned["fallback"] = cleansimpleopt("fallback", opts, { "table", "string" }, {}, "habamax", path)
	if type(cleaned.fallback) == "table" then
		cleaned.fallback = getcleanedtheme(cleaned.fallback, "fallback")
	else
		cleaned.fallback = { colorscheme = cleaned.fallback, name = cleaned.fallback }
	end
	cleaned["fallback_setup"] = cleansimpleopt("fallback_setup", opts, { "function" }, {}, nil, path)
	cleaned["always_setup"] = cleansimpleopt("always_setup", opts, { "function" }, {}, nil, path)
	cleaned["fallback_closer"] = cleansimpleopt("fallback_closer", opts, { "function" }, {}, nil, path)
	cleaned["always_closure"] = cleansimpleopt("always_closure", opts, { "function" }, {}, nil, path)
	cleaned["make_Color_cmd"] = cleansimpleopt("make_Color_cmd", opts, { "boolean" }, {}, true, path)
	cleaned["make_Debugthemesprint_cmd"] = cleansimpleopt(
		"make_Debugthemesprint_cmd",
		opts,
		{ "boolean" },
		{},
		false,
		path
	)
	cleaned["Themes_cmd"] = cleansimpleopt("Themes_cmd", opts, { "table" }, {}, {
		make = true,
		live_preview = true,
	}, path)
	cleaned["Themes_cmd"] = getcleanedThemes_cmd(cleaned["Themes_cmd"], "Themes_cmd")

	return cleaned
end

function M.set(opts)
	config = getcleaned(opts)
end

function M.get()
	return config
end

return M
