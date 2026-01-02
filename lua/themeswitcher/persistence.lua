local M = {}
local filepath = vim.fn.stdpath("data") .. "/colorscheme"

function M.write(x)
	vim.fn.writefile({ x }, filepath)
end

function M.read()
	if vim.fn.filereadable(filepath) ~= 1 then
		return
	end
	return vim.fn.readfile(filepath)
end

return M
