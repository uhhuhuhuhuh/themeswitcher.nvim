local config = {}
local M = {}

local function deepcopy(og)
    local ogtype = type(og)
    local copy
    if ogtype == "table" then
        copy = {}
        for ogkey, ogvalue in next, og, nil do
            copy[deepcopy(ogkey)] = deepcopy(ogvalue)
        end
        setmetatable(copy, deepcopy(getmetatable(og)))
    else
        copy = og
    end
    return copy
end

local function cleansimpleopt(cleaned, key, opts, types, values, default, path, required)
    required = required ~= nil and required or false
    if path ~= "" then
        path = type(key) == "number" and path .. "[" .. tostring(key) .. "]" or path .. "." .. key
    else
        path = key
    end
    if opts[key] == nil then
        if required == true then
            vim.notify(path .. " is required", vim.log.levels.ERROR)
        end
        cleaned[key] = default
        return
    end

    local keytype = type(opts[key])
    local isin = false
    for i = 1, #types do
        if types[i] == keytype then
            isin = true
            break
        end
    end
    if not isin then
        vim.notify(path .. " has wrong type: " .. keytype, vim.log.levels.ERROR)
        cleaned[key] = default
        return
    end

    if #values > 0 then
        isin = false
        for _, value in ipairs(values) do
            if opts[key] == value then
                isin = true
            end
        end
        if not isin then
            vim.notify(path .. " has wrong value: " .. opts[key], vim.log.levels.ERROR)
            cleaned[key] = default
            return
        end
    end

    cleaned[key] = opts[key]
end

local function cleanctntofname(name, join_symbol, default)
    if string.find(name, join_symbol, 1, true) ~= nil then
        vim.notify(name .. " has join symbol within it", vim.log.levels.ERROR)
        return default
    end
    return name
end

local function setcleanedthemeandname(themes, paths, themepaths, i, join_symbol, path, nameprefix)
    local new = themes[i]
    cleansimpleopt(new, "colorscheme", new, { "string" }, {}, "default", path, true)
    cleansimpleopt(new, "name", new, { "string" }, {}, new.colorscheme, path)
    cleanctntofname(new["name"], join_symbol, "ERROR can't have join_symbol in it " .. tostring(i))
    cleansimpleopt(new, "bg", new, { "string" }, { "dark", "light" }, nil, path)
    cleansimpleopt(new, "setup", new, { "function" }, {}, nil, path)
    cleansimpleopt(new, "closure", new, { "function" }, {}, nil, path)
    local path = nameprefix .. new.name
    paths[#paths + 1] = { path = path, isgroup = false }
    themepaths[#themepaths + 1] = path
    themes[new.name] = new
    themes[new.name].isgroup = false
    themes[new.name].name = nil
    themes[i] = nil
end

local setcleanedThemes_cmd = function(themescmd, path)
    cleansimpleopt(themescmd, "make", themescmd, { "boolean" }, {}, true, path)
    cleansimpleopt(themescmd, "live_preview", themescmd, { "boolean" }, {}, true, path)
end

-- need to set paths here so that the order of the names is preserved
-- also returns the size of the themes
local function setcleanedthemesandpaths(themes, paths, themepaths, groups, join_symbol, gobd, opts, path, nameprefix)
    nameprefix = nameprefix or ""
    local count = 0
    for i = 1, #themes do
        local theme = themes[i]
        count = count + 1

        cleansimpleopt(
            themes,
            i,
            themes,
            { "table", "string" },
            {},
            { colorscheme = "default", name = "error " .. tostring(i) },
            path .. "themes"
        )

        if type(theme) == "string" then
            themes[theme] = { colorscheme = theme, isgroup = false }
            local path = nameprefix .. theme
            paths[#paths + 1] = { path = path, isgroup = false }
            themepaths[#themepaths + 1] = path
            theme = nil
            goto continue
        end
        if theme.themes == nil then
            setcleanedthemeandname(themes, paths, themepaths, i, join_symbol, path .. "themes", nameprefix)
            goto continue
        end

        cleansimpleopt(theme, "themes", theme, { "table" }, {}, {}, path)
        cleansimpleopt(theme,
            "name",
            theme,
            { "string" },
            {},
            "error " .. tostring(i),
            path .. "themes[" .. tostring(i) .. "]",
            true
        )
        theme.name =
            cleanctntofname(theme.name, join_symbol, "ERROR " .. tostring(i) .. " can't have join_symbol in it")

        -- make sure the group is added before its members
        paths[#paths + 1] = { path = nameprefix .. theme.name, isgroup = true }
        groups[#paths] = gobd

        local idx = #paths
        local size = setcleanedthemesandpaths(theme.themes, paths, themepaths, groups, join_symbol, gobd, opts,
            "themes[" .. tostring(i) .. "].",
            nameprefix .. theme.name .. join_symbol)
        paths[idx].size = size
        count = count + size
        themes[theme.name] = deepcopy(theme)
        themes[theme.name].isgroup = true
        themes[theme.name].name = nil
        theme = nil

        ::continue::
    end

    return count
end

local function clean(config, opts, paths, themepaths, groups)
    local path = ""
    cleansimpleopt(config, "join_symbol", opts, { "string" }, {}, "/", path)
    cleansimpleopt(config, "groups_open_by_default", opts, { "boolean" }, {}, false, path)
    cleansimpleopt(config, "themes", opts, { "table" }, {}, {}, path)
    setcleanedthemesandpaths(config.themes, paths, themepaths, groups, config["join_symbol"],
        config["groups_open_by_default"],
        opts, path)
    cleansimpleopt(config, "fallback", opts, { "table", "string" }, {}, "habamax", path)
    if type(config.fallback) == "table" then
        config.fallback = setcleanedthemeandname(config.fallback, "fallback")
    else
        config.fallback = {
            colorscheme = config.fallback,
            name = cleanctntofname(config.fallback, config.join_symbol,
                "ERROR")
        }
    end
    cleansimpleopt(config, "fallback_setup", opts, { "function" }, {}, nil, path)
    cleansimpleopt(config, "always_setup", opts, { "function" }, {}, nil, path)
    cleansimpleopt(config, "fallback_closer", opts, { "function" }, {}, nil, path)
    cleansimpleopt(config, "always_closure", opts, { "function" }, {}, nil, path)
    cleansimpleopt(config, "make_Color_cmd", opts, { "boolean" }, {}, true, path)
    cleansimpleopt(config, "smart_next_prev_in_UI", opts, { "boolean" }, {}, true, path)
    cleansimpleopt(config, "Themes_cmd", opts, { "table" }, {}, {
        make = true,
        live_preview = true,
    }, path)
    setcleanedThemes_cmd(config["Themes_cmd"], "Themes_cmd")

    cleansimpleopt(
        config,
        "DEBUG",
        opts,
        { "boolean" },
        {},
        false,
        path
    )
end

function M.set(opts, paths, themepaths, groups)
    clean(config, opts, paths, themepaths, groups)
end

function M.get()
    return config
end

return M
