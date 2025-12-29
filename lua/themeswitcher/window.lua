-- Thanks to themery.nvim for I used their window.lua code to understand how vim buffers and windows work!
-- https://github.com/zaldih/themery.nvim

local M = {}
local buf
local win

local gettransform = function()
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")
	local bufwidth = math.ceil(width * 0.4)
	local bufheight = math.ceil(height * 0.5 - 4)
	return {
		row = math.ceil((height - bufheight) / 2 - 1),
		col = math.ceil((width - bufwidth) / 2),
		height = bufheight,
		width = bufwidth,
	}
end

function M.close()
	vim.api.nvim_win_close(win, true)
end

function M.open(movedfunc)
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("filetype", "themes", { buf = buf })
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

	local groupid = vim.api.nvim_create_augroup("themesfocus", { clear = true })
	vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
		group = groupid,
		buffer = buf,
		callback = M.close,
		once = true,
	})
	groupid = vim.api.nvim_create_augroup("themesmoved", { clear = true })
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMoved" }, {
		group = groupid,
		buffer = buf,
		callback = movedfunc,
	})

	local transform = gettransform()

	local opts = {
		style = "minimal",
		relative = "editor",
		border = "single",
		width = transform.width,
		height = transform.height,
		row = transform.row,
		col = transform.col,
	}

	win = vim.api.nvim_open_win(buf, true, opts)
	vim.api.nvim_set_option_value("cursorline", true, { win = win })

	local title = "themeswitcher.nvim"
	title = string.rep(" ", math.floor(transform.width / 2) - math.floor(string.len(title) / 2)) .. title
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { title })
end

function M.buf()
	return buf
end

function M.win()
	return win
end

return M
