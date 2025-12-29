-- The index used by applytheme
local currtheme = 1
-- Used for previewing themes, stores the applied theme but not the theme which is being previewed
-- If previewing is not occurring then it's value is nil
local appliedtheme = nil
local config = require("themeswitcher.config")
local persistence = require("themeswitcher.persistence")
local window = require("themeswitcher.window")
local M = {}

-- hidden

local notify = function()
	if config.get().themes[currtheme] == nil then
		return
	end
	vim.notify("Switched to colorscheme, " .. config.get().themes[currtheme].name)
end

local applytheme = function(save)
	save = save or true
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
	if save == true then
		persistence.write(config.get().themes[currtheme].name)
	end
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
local updatewindow
local updatewindowcursor = function()
	updatewindow(vim.fn.line("."))
end
updatewindow = function(position, updatecursor)
	updatecursor = updatecursor or false
	vim.api.nvim_set_option_value("modifiable", true, { buf = window.buf() })

	if #config.get().themes == 0 then
		vim.api.nvim_buf_set_lines(window.buf(), 1, -1, false, { "  No Themes Loaded..." })
		vim.api.nvim_set_option_value("modifiable", false, { buf = window.buf() })
		return
	end

	-- Is different from M.get_names
	local names = {}
	for i, t in ipairs(config.get().themes) do
		local prefix = "  "
		if i == appliedtheme then
			prefix = "> "
		end
		table.insert(names, prefix .. t.name)
	end

	vim.api.nvim_buf_set_lines(window.buf(), 1, -1, false, names)
	if updatecursor == true then
		vim.api.nvim_win_set_cursor(window.win(), { position, 0 })
	end
	vim.api.nvim_set_option_value("modifiable", false, { buf = window.buf() })

	if position < 2 then
		return
	end
	currtheme = position - 1
	if config.get().Themes_cmd.live_preview == true then
		applytheme(false)
	end
end
local closewindow = function()
	window.close()
	currtheme = appliedtheme
	applytheme()
	appliedtheme = nil
end
local closewindowapply = function()
	window.close()
	applytheme()
	appliedtheme = nil
end
local openwindow = function()
	window.open(updatewindowcursor)
	appliedtheme = currtheme
	updatewindow(appliedtheme + 1, true)
	local mappings = {
		q = closewindow,
		["<Esc>"] = closewindow,
		["<Cr>"] = closewindowapply,
	}

	for k, v in pairs(mappings) do
		vim.keymap.set("n", k, v, {
			buffer = window.buf(),
			noremap = true,
			silent = true,
		})
	end
end

function M.set_theme(name)
	local old = currtheme
	for i, theme in ipairs(config.get().themes) do
		if name == theme.name then
			if appliedtheme ~= nil then
				updatewindow(i + 1, true)
				return
			end
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

	if appliedtheme ~= nil then
		updatewindow(idx + 1, true)
		return
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
	local new = currtheme
	if new == #config.get().themes then
		new = 1
	else
		new = new + 1
	end
	if appliedtheme ~= nil then
		updatewindow(new + 1, true)
		return
	end
	local old = currtheme
	currtheme = new
	if not pcall(applytheme) then
		currtheme = old
		return
	end
	notify()
end

function M.prev()
	local new = currtheme
	if new == 1 then
		new = #config.get().themes
	else
		new = new - 1
	end
	if appliedtheme ~= nil then
		updatewindow(new + 1, true)
		return
	end
	local old = currtheme
	currtheme = new
	if not pcall(applytheme) then
		currtheme = old
		return
	end
	notify()
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
	if config.get().Themes_cmd.make == true then
		vim.api.nvim_create_user_command("Themes", openwindow, {})
	end
end

return M
