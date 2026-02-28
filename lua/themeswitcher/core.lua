-- The index used by applytheme
local currtheme = 1

local uistate = {
	appliedtheme = nil,
	postopathidx = nil,
	cursorpos = nil,
}

local paths = {}
local themepaths = {}
local groups = {}

local config = require("themeswitcher.config")
local persistence = require("themeswitcher.persistence")
local window = require("themeswitcher.window")
local M = {}

-- hidden

local function getfrompath(path)
	local themes = config.get().themes
	local current = themes
	local segments = {}
	for segment in string.gmatch(path, "[^" .. config.get().join_symbol .. "/]+") do
		table.insert(segments, segment)
	end

	local lastseg = ""
	for i, segment in ipairs(segments) do
		lastseg = segment
		current = current[segment]
		if not current then
			return nil
		end
		if current.isgroup and i < #segments then
			current = current.themes
		end
	end

	return { theme = current, name = lastseg }
end

local function notify()
	if paths[currtheme] == nil then
		return
	end
	vim.notify("Switched to colorscheme, " .. paths[currtheme].path)
end

local function applytheme(save)
	save = save or true
	local path = paths[currtheme].path
	local theme = getfrompath(path).theme

	if theme == nil or theme.isgroup == true then
		vim.notify("Theme not found", vim.log.levels.ERROR)
		error("Bad theme")
	end
	if theme.colorscheme == nil then
		vim.notify("Invalid theme provided: " .. path, vim.log.levels.ERROR)
		error("Bad theme")
	end
	if theme.setup ~= nil then
		theme.setup()
	elseif config.get().fallback_setup ~= nil then
		config.get().fallback_setup()
	end
	if config.get().always_setup ~= nil then
		config.get().always_setup()
	end
	if theme.bg ~= nil then
		vim.o.background = theme.bg
	end

	if not pcall(vim.cmd.color, theme.colorscheme) then
		vim.notify("Failed to load colorscheme: " .. path, vim.log.levels.ERROR)
	end

	if theme.closure ~= nil then
		theme.closure()
	elseif config.get().fallback_closure ~= nil then
		config.get().fallback_closure()
	end
	if theme.always_closure ~= nil then
		config.get().always_closure()
	end
	if save == true then
		persistence.write(path)
	end
end
local function loadpersist()
	local persisttheme = persistence.read()
	if persisttheme == nil or #persisttheme == 0 then
		return
	end
	currtheme = 0
	for i, x in ipairs(paths) do
		if x.path == persisttheme[1] then
			currtheme = i
			break
		end
	end

	-- either apply theme or fallback
	if currtheme == 0 or not pcall(applytheme) then
		if currtheme == 0 then
			vim.notify("themeswitcher.nvim: can not find theme located in persist file", vim.log.levels.ERROR)
			-- no need to notify for apply theme failure because it already does notify errors
		end
		if config.get().fallback == nil then
			return
		end
		if not pcall(vim.cmd.colorscheme, config.get().fallback.colorscheme) then
			vim.notify("Failed to load fallback, " .. config.get().fallback.name, vim.log.levels.ERROR)
		end
	end
end
local function updatewindow(position, updatecursor, skippreview)
	updatecursor = updatecursor == nil and false or updatecursor
	skippreview = skippreview == nil and false or skippreview
	vim.api.nvim_set_option_value("modifiable", true, { buf = window.buf() })

	if #paths == 0 then
		vim.api.nvim_buf_set_lines(window.buf(), 1, -1, false, { "  No Themes Loaded..." })
		vim.api.nvim_set_option_value("modifiable", false, { buf = window.buf() })
		return
	end

	local names = {}
	local sizes = {}
	local jump = 0
	local offset = 0
	local map = {}
	for i, path in ipairs(paths) do
		for j, n in ipairs(sizes) do
			sizes[j] = n - 1
			if sizes[j] <= 0 then
				sizes[j] = nil
			end
		end

		if jump > 0 then
			jump = jump - 1
			goto continue
		end

		local name = getfrompath(path.path).name

		map[i - offset] = i

		if path.isgroup == true then
			local prefix = " "
			if groups[i] == false then
				prefix = " "
				jump = path.size
				offset = offset + jump
				for _ = 1, #sizes do
					prefix = "   " .. prefix
				end
			else
				table.insert(sizes, path.size + 1)
				for _ = 1, #sizes - 1 do
					prefix = "   " .. prefix
				end
			end

			table.insert(names, prefix .. name)
			goto continue
		end

		local prefix = "  "
		if i == uistate.appliedtheme then
			if position == nil then
				position = i - offset + 1
			end
			prefix = "*" .. prefix:sub(2, prefix:len())
		end
		for _ = 1, #sizes do
			prefix = prefix .. "   "
		end

		table.insert(names, prefix .. name)

		::continue::
	end

	vim.api.nvim_buf_set_lines(window.buf(), 1, -1, false, names)
	if position == nil then
		position = vim.fn.line(".")
	end
	if updatecursor == true then
		vim.api.nvim_win_set_cursor(window.win(), { position, 0 })
	end
	uistate.cursorpos = position
	vim.api.nvim_set_option_value("modifiable", false, { buf = window.buf() })

	-- is a theme not a group name
	uistate.postopathidx = map[position - 1]
	if config.get().Themes_cmd.live_preview == false or skippreview == true then
		return
	end
	if position == 1 then
		return
	end
	if paths[map[position - 1]] == nil then
		vim.notify("BUG", vim.log.levels.ERROR)
		return
	end
	if paths[map[position - 1]].isgroup == true then
		return
	end
	if map[position - 1] == currtheme then
		return
	end
	currtheme = map[position - 1]
	if config.get().Themes_cmd.live_preview == true then
		applytheme(false)
	end
end
local function updatewindowcursor()
	updatewindow(vim.fn.line("."))
end
function M.close_window()
	window.close()
	currtheme = uistate.appliedtheme
	applytheme()
	uistate.appliedtheme = nil
	uistate.postopathidx = nil
end

local function onenter()
	if paths[uistate.postopathidx].isgroup == false then
		uistate.appliedtheme = currtheme
	else
		groups[uistate.postopathidx] = not groups[uistate.postopathidx]
	end
	updatewindow(nil, nil, true)
end
function M.open_window()
	window.open(updatewindowcursor)
	uistate.appliedtheme = currtheme
	if uistate.cursorpos == nil then
		updatewindow(nil, true)
	else
		updatewindow(uistate.cursorpos, true)
	end
	local mappings = {
		q = M.close_window,
		["<Esc>"] = M.close_window,
		["<Cr>"] = onenter,
	}

	for k, v in pairs(mappings) do
		vim.keymap.set("n", k, v, {
			buffer = window.buf(),
			noremap = true,
			silent = true,
		})
	end
end

function M.set_theme(path)
	local old = currtheme
	currtheme = 0
	for i, n in ipairs(paths) do
		if n.path == path then
			currtheme = i
			if n.isgroup == true then
				vim.notify("Can not set a group theme, " .. path, vim.log.levels.ERROR)
				return
			end
		end
	end
	if currtheme == 0 then
		vim.notify("Failed to find colorscheme, " .. path, vim.log.levels.ERROR)
		return
	end

	if not pcall(applytheme) then
		currtheme = old
	else
		notify()
	end
end

function M.set_theme_idx(idx)
	if idx < 1 or idx > #paths then
		vim.notify("Failed to find colorscheme from index, " .. idx, vim.log.levels.ERROR)
	end

	if uistate.appliedtheme ~= nil then
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

function M.get_paths()
	return paths
end

function M.get_theme_paths()
	return themepaths
end

function M.next()
	if #paths == 0 then
		return
	end

	local new = currtheme
	if new == #paths then
		new = 1
	else
		new = new + 1
	end
	while paths[new].isgroup == true do
		if new == #paths then
			new = 1
		else
			new = new + 1
		end
	end

	if uistate.appliedtheme ~= nil then
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
	if #paths == 0 then
		return
	end

	local new = currtheme
	if new == 1 then
		new = #paths
	else
		new = new - 1
	end
	while paths[new].isgroup == true do
		if new == 1 then
			new = #paths
		else
			new = new - 1
		end
	end

	if uistate.appliedtheme ~= nil then
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
	config.set(opts, paths, themepaths, groups)
	loadpersist()

	if config.get().make_Color_cmd == true then
		vim.api.nvim_create_user_command("Color", function(opts)
			M.set_theme(opts.args)
		end, {
			nargs = 1,
			desc = "Select colorscheme from themes table",
			complete = function()
				return themepaths
			end,
		})
	end

	if config.get().DEBUG == true then
		local getfuncs = {
			["themes"] = function()
				return config.get().themes
			end,
			["paths"] = function()
				return paths
			end,
			["themepaths"] = function()
				return themepaths
			end,
			["groups"] = function()
				return groups
			end,
			["uistate.appliedtheme"] = function()
				if uistate.appliedtheme == nil then
					return nil
				end
				return {
					path = (paths[uistate.appliedtheme] == nil and "nil" or paths[uistate.appliedtheme]),
					idx = uistate.appliedtheme,
				}
			end,
			["currtheme"] = function()
				if currtheme == nil then
					return nil
				end
				return { path = (paths[currtheme] == nil and "nil" or paths[currtheme]), idx = currtheme }
			end,
			["uistate.postopathidx"] = function()
				if currtheme == nil then
					return nil
				end
				return {
					path = (paths[uistate.postopathidx] == nil and "nil" or paths[uistate.postopathidx]),
					idx = currtheme,
				}
			end,
		}
		vim.api.nvim_create_user_command("DEBUGthemeswitcher", function(opts)
			local get = getfuncs[opts.args]
			if get == nil then
				vim.notify("DEBUGthemeswitcher, Invalid command: " .. opts.args, vim.log.levels.ERROR)
				return
			end
			print(vim.inspect(get()))
		end, {
			nargs = 1,
			desc = "themeswitcher.nvim debug printer",
			complete = function()
				local res = {}
				for key, _ in pairs(getfuncs) do
					table.insert(res, key)
				end
				return res
			end,
		})
	end

	if config.get().Themes_cmd.make == true then
		vim.api.nvim_create_user_command("Themes", M.open_window, { desc = "UI to select and pick themes" })
	end
end

return M
