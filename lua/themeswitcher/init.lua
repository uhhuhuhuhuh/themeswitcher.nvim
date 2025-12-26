local currtheme = 1
local config = {}
local M = {}

-- hidden
local notify = function()
	if config.themes[currtheme] == nil then
		return
	end
	vim.notify("Switched to colorscheme, " .. config.themes[currtheme].name)
end

local applytheme = function()
	local colorscheme
	if config.themes[currtheme] == nil then
		return
	end
	if config.themes[currtheme].colorscheme == nil then
		vim.notify("Invalid theme provided: " .. config.themes[currtheme], vim.log.levels.ERROR)
		error("Bad theme")
	else
		colorscheme = config.themes[currtheme].colorscheme
	end
	if config.themes[currtheme].setup ~= nil then
		config.themes[currtheme].setup()
	elseif config.fallback_setup ~= nil then
		config.fallback_setup()
	end
	if config.always_setup ~= nil then
		config.always_setup()
	end
	if config.themes[currtheme].bg ~= nil then
		vim.o.background = config.themes[currtheme].bg
	end
	if not pcall(vim.cmd.colorscheme, colorscheme) then
		if config.themes[currtheme].name == nil then
			vim.notify(tostring(currtheme))
		else
			vim.notify("Failed to load colorscheme: " .. config.themes[currtheme].name, vim.log.levels.ERROR)
		end
		error("Bad theme")
		return
	end
	if config.themes[currtheme].closure ~= nil then
		config.themes[currtheme].closure()
	elseif config.fallback_closure ~= nil then
		config.fallback_closure()
	end
	if config.themes[currtheme].always_closure ~= nil then
		config.always_closure()
	end
	vim.fn.writefile({ config.themes[currtheme].name }, vim.fn.stdpath("data") .. "/colorscheme")
end
local applyorfallback = function()
	if pcall(applytheme) then
		notify()
		return
	end
	if config.fallback == nil then
		return
	end
	if not pcall(vim.cmd.colorscheme, config.fallback.colorscheme) then
		vim.notify("Failed to load fallback, " .. config.fallback.name, vim.log.levels.ERROR)
	end
end
local findtheme = function(theme)
	for i, t in ipairs(config.themes) do
		if t.name == theme then
			return i
		end
	end
end

-- public

function M.set_theme(name)
	local old = currtheme
	for i, theme in ipairs(config.themes) do
		if name == theme.name then
			currtheme = i
			if not pcall(applytheme) then
				currtheme = old
			else
				notify()
			end
			return
		end
	end
	vim.notify("Failed to find colorscheme, " .. name, vim.log.levels.ERROR)
end

function M.get_themes()
	return config.themes
end

function M.get_names()
	local names = {}
	for _, theme in ipairs(config.themes) do
		table.insert(names, theme.name)
	end
	return names
end

function M.next()
	local old = currtheme
	if currtheme == #config.themes then
		currtheme = 1
	else
		currtheme = currtheme + 1
	end
	if not pcall(applytheme) then
		currtheme = old
	else
		notify()
	end
end

function M.prev()
	local old = currtheme
	if currtheme == 1 then
		currtheme = #config.themes
	else
		currtheme = currtheme - 1
	end
	if not pcall(applytheme) then
		currtheme = old
	else
		notify()
	end
end

function M.setup(opts)
	config = require("themeswitcher.config").parse_config(opts)
	config = require("themeswitcher.config").complete_themes_from_config(config)

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
	applyorfallback()
	if config.make_Color_cmd == true then
		vim.api.nvim_create_user_command("Color", function(opts)
			M.set_theme(opts.args)
		end, {
			nargs = 1,
			desc = "Select colorscheme from colorschemes table",
			complete = function()
				local items = {}
				for _, theme in ipairs(config.themes) do
					table.insert(items, theme.name)
				end
				return items
			end,
		})
	end
end

return M
