local core = require("themeswitcher.core")

local function setup(opts)
	core.set_config(opts)

	core.load_persist()

	if core.get_config().make_Color_cmd == true then
		core.create_Color_cmd()
	end

	if core.get_config().Themes_cmd.make == true then
		core.create_Themes_cmd()
	end

	if core.get_config().DEBUG == true then
		core.create_DEBUG_cmd()
	end
end

return {
	setup = setup,
	open_window = core.open_window,
	close_window = core.close_window,
	set_theme = core.set_theme,
	set_theme_idx = core.set_theme_idx,
	get_themes = core.get_themes,
	get_paths = core.get_paths,
	get_theme_paths = core.get_theme_paths,
	next = core.next,
	prev = core.prev,
}
