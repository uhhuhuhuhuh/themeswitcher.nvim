local currtheme = 1
local config = {}
local M = {}
local themes
local fallback
local fallback_setup
local always_setup

-- hidden
local getname = function(theme)
	if theme.name ~= nil then
		return theme.name
	end
	if theme.colorscheme ~= nil then
		return theme.colorscheme
	end

	-- not a table must be a string
	return theme
end
local notify = function()
	if themes[currtheme] == nil then
		return
	end
	vim.notify("Switched to colorscheme, " .. getname(themes[currtheme]))
end

local applytheme = function()
	local colorscheme
	if themes[currtheme] == nil then
		return
	end
	if themes[currtheme].colorscheme == nil then
		if type(themes[currtheme]) == "string" then
			colorscheme = themes[currtheme]
		else
			vim.notify("Invalid theme provided: " .. themes[currtheme], vim.log.levels.ERROR)
			error("Bad theme")
			return
		end
	else
		colorscheme = themes[currtheme].colorscheme
	end
	if themes[currtheme].setup ~= nil then
		themes[currtheme].setup()
	elseif fallback_setup ~= nil then
		fallback_setup()
	end
	if always_setup ~= nil then
		always_setup()
	end
	if themes[currtheme].bg ~= nil then
		vim.o.background = themes[currtheme].bg
	end
	local ok = pcall(vim.cmd.colorscheme, colorscheme)
	if not ok then
		vim.notify("Failed to load colorscheme: " .. getname(themes[currtheme]), vim.log.levels.ERROR)
		error("Bad theme")
		return
	end
	if themes[currtheme].post_coloring ~= nil then
		themes[currtheme].post_coloring()
	end
	vim.fn.writefile({ getname(themes[currtheme]) }, vim.fn.stdpath("data") .. "/colorscheme")
end
local apply = function()
	if pcall(applytheme) then
		notify()
		return
	end
	if fallback == nil then
		return
	end
	if not pcall(vim.cmd.colorscheme, fallback) then
		vim.notify("Failed to load fallback: " .. fallback, vim.log.levels.ERROR)
	end
end
local isvalidtheme = function(theme)
	if theme == nil then
		return false
	end
	if type(theme) == "string" then
		return true
	end
	if type(theme) ~= "table" then
		return false
	end
	if type(theme.colorscheme) ~= "string" then
		return false
	end
	if theme.name ~= nil and type(theme.name) ~= "string" then
		return false
	end
	if theme.setup ~= nil and type(theme.setup) ~= "function" then
		return false
	end
	if theme.bg ~= nil and theme.bg ~= "dark" and theme.bg ~= "light" then
		return false
	end
	if type(theme.post_coloring) ~= "function" and type(theme.post_coloring) ~= "nil" then
		return false
	end

	return true
end
local findtheme = function(theme)
	for i, t in ipairs(themes) do
		if getname(t) == theme then
			return i
		end
	end
end

-- public

function M.set_theme(name)
	for i, theme in ipairs(themes) do
		if name == getname(theme) then
			currtheme = i
			apply()
			return
		end
	end
	vim.notify("Failed to find colorscheme, " .. name, vim.log.levels.ERROR)
end

function M.get_themes()
	return themes
end

function M.get_names()
	local names = {}
	for _, theme in ipairs(themes) do
		table.insert(names, getname(theme))
	end
	return names
end

function M.next()
	if currtheme == #themes then
		currtheme = 1
	else
		currtheme = currtheme + 1
	end
	apply()
end

function M.prev()
	if currtheme == 1 then
		currtheme = #themes
	else
		currtheme = currtheme - 1
	end
	apply()
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", require("themeswitcher.defaults"), opts or {})
	if type(config.themes) == "table" then
		themes = config.themes
		-- check validity of themesarg
		local errmsg = ""
		for i, theme in ipairs(themes) do
			if isvalidtheme(theme) == false then
				errmsg = errmsg .. "Invalid theme at idx: " .. tostring(i) .. ": " .. tostring(theme) .. "\n"
			end
		end
		if errmsg ~= "" then
			vim.notify(errmsg, "error")
			return
		end
		-- load saved colorscheme
		local savefilename = vim.fn.stdpath("data") .. "/colorscheme"
		if vim.fn.filereadable(savefilename) == 1 then
			local savefile = vim.fn.readfile(savefilename)

			if savefile and #savefile > 0 then
				local findresults = findtheme(savefile[1])

				if findresults ~= nil then
					currtheme = findresults
				end
			end
		end
		applytheme()
	end
	if config.make_Color_cmd == true then
		vim.api.nvim_create_user_command("Color", function(opts)
			M.set_theme(opts.args)
		end, {
			nargs = 1,
			desc = "Select colorscheme from colorschemes table",
			complete = function()
				local items = {}
				for _, theme in ipairs(themes) do
					table.insert(items, getname(theme))
				end
				return items
			end,
		})
	end
	fallback = config.fallback
	fallback_setup = config.fallback_setup
	always_setup = config.always_setup
end

return M
