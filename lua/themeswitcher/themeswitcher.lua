local currtheme = 1
local config = require("themeswitcher.config")
local persistence = require("themeswitcher.persistence")
local M = {}

-- hidden
local notify = function()
	if config.get().themes[currtheme] == nil then
		return
	end
	vim.notify("Switched to colorscheme, " .. config.get().themes[currtheme].name)
end

local applytheme = function()
	local colorscheme
	if config.get().themes[currtheme] == nil then
		error("Bad theme")
	end
	if config.get().themes[currtheme].colorscheme == nil then
		vim.notify("Invalid theme provided: " .. config.get().themes[currtheme], vim.log.levels.ERROR)
		error("Bad theme")
	else
		colorscheme = config.get().themes[currtheme].colorscheme
	end
	if config.get().themes[currtheme].setup ~= nil then
		config.get().themes[currtheme].setup()
	elseif config.get().fallback_setup ~= nil then
		config.get().fallback_setup()
	end
	if config.get().always_setup ~= nil then
		config.get().always_setup()
	end
	if config.get().themes[currtheme].bg ~= nil then
		vim.o.background = config.get().themes[currtheme].bg
	end
	if not pcall(vim.cmd.colorscheme, colorscheme) then
		vim.notify("Failed to load colorscheme: " .. config.get().themes[currtheme].name, vim.log.levels.ERROR)
		error("Bad theme")
		return
	end
	if config.get().themes[currtheme].closure ~= nil then
		config.get().themes[currtheme].closure()
	elseif config.get().fallback_closure ~= nil then
		config.get().fallback_closure()
	end
	if config.get().themes[currtheme].always_closure ~= nil then
		config.get().always_closure()
	end
	persistence.write(config.get().themes[currtheme].name)
end
local findtheme = function(theme)
	for i, t in ipairs(config.get().themes) do
		if t.name == theme then
			return i
		end
	end
end
local loadpersist = function()
	local persisttheme = persistence.read()
	if persisttheme ~= nil and #persisttheme > 0 then
		currtheme = findtheme(persisttheme[1])
	end
	if not pcall(applytheme) then
		currtheme = 0
		if config.get().fallback == nil then
			return
		end
		if not pcall(vim.cmd.colorscheme, config.get().fallback.colorscheme) then
			vim.notify("Failed to load fallback, " .. config.get().fallback.name, vim.log.levels.ERROR)
		end
	end
end

function M.set_theme(name)
	local old = currtheme
	for i, theme in ipairs(config.get().themes) do
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

function M.set_theme_idx(idx)
	if idx < 1 or idx > #config.get().themes then
		vim.notify("Failed to find colorscheme from index, " .. idx, vim.log.levels.ERROR)
	end

	local old = currtheme
	currtheme = idx
	if not pcall(applytheme) then
		currtheme = old
	else
		notify()
	end
end

function M.get_themes()
	return config.get().themes
end

function M.get_names()
	local names = {}
	for _, theme in ipairs(config.get().themes) do
		table.insert(names, theme.name)
	end
	return names
end

function M.next()
	local old = currtheme
	if currtheme == #config.get().themes then
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
		currtheme = #config.get().themes
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
	config.set(opts)
	loadpersist()
	if config.get().make_Color_cmd == true then
		vim.api.nvim_create_user_command("Color", function(opts)
			M.set_theme(opts.args)
		end, {
			nargs = 1,
			desc = "Select colorscheme from colorschemes table",
			complete = function()
				return M.get_names()
			end,
		})
	end
end

return M
