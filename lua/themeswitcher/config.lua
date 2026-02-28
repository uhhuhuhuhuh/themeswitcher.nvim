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

local function cleansimpleopt(key, opts, types, values, default, path, required)
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
        vim.notify(path .. " has wrong type: " .. keytype, vim.log.levels.ERROR)
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
            vim.notify(path .. " has wrong value: " .. opts[key], vim.log.levels.ERROR)
            return default
        end
    end

    return opts[key]
end

local function cleanctntofname(name, join_symbol, default)
    if string.find(name, join_symbol) ~= nil then
        vim.notify(name .. " has join symbol within it", vim.log.levels.ERROR)
        return default
    end
    return name
end

local function setcleanedthemeandname(themes, paths, themepaths, i, join_symbol, path, nameprefix)
    local new = themes[i]
    new["colorscheme"] = cleansimpleopt("colorscheme", new, { "string" }, {}, "default", path, true)
    new["name"] = cleansimpleopt("name", new, { "string" }, {}, new.colorscheme, path)
    new["name"] = cleanctntofname(new["name"], join_symbol, "ERROR can't have join_symbol in it " .. tostring(i))
    new["bg"] = cleansimpleopt("bg", new, { "string" }, { "dark", "light" }, nil, path)
    new["setup"] = cleansimpleopt("setup", new, { "function" }, {}, nil, path)
    new["closure"] = cleansimpleopt("closure", new, { "function" }, {}, nil, path)
    table.insert(paths, { path = nameprefix .. new.name, isgroup = false })
    table.insert(themepaths, nameprefix .. new.name)
    themes[new.name] = new
    themes[new.name].isgroup = false
    themes[new.name].name = nil
    themes[i] = nil
end

local getcleanedThemes_cmd = function(themescmd, path)
    local new = themescmd
    new["make"] = cleansimpleopt("make", new, { "boolean" }, {}, true, path)
    new["live_preview"] = cleansimpleopt("live_preview", new, { "boolean" }, {}, true, path)
    return new
end

-- need to set names here so that the order of the names is preserved
-- also returns the size of the themes
local function setcleanedthemesandnames(themes, paths, themepaths, groups, join_symbol, gobd, opts, path, nameprefix)
    nameprefix = nameprefix or ""
    local count = 0
    for i, t in ipairs(themes) do
        count = count + 1

        themes[i] = cleansimpleopt(
            i,
            themes,
            { "table", "string" },
            {},
            { colorscheme = "default", name = "error " .. tostring(i) },
            path .. "themes"
        )

        if type(t) == "string" then
            themes[t] = { colorscheme = t, isgroup = false }
            themes[i] = nil
            table.insert(paths, { path = nameprefix .. t, isgroup = false })
            table.insert(themepaths, nameprefix .. t)
            goto continue
        end
        if themes[i].themes == nil then
            setcleanedthemeandname(themes, paths, themepaths, i, join_symbol, path .. "themes", nameprefix)
            goto continue
        end

        themes[i].themes = cleansimpleopt("themes", themes[i], { "table" }, {}, {}, path)
        themes[i].name = cleansimpleopt(
            "name",
            themes[i],
            { "string" },
            {},
            "error " .. tostring(i),
            path .. "themes[" .. tostring(i) .. "]",
            true
        )
        themes[i].name =
            cleanctntofname(themes[i].name, join_symbol, "ERROR " .. tostring(i) .. " can't have join_symbol in it")

        -- make sure the group is added before its members
        table.insert(paths, { path = nameprefix .. themes[i].name, isgroup = true })
        groups[#paths] = gobd

        local idx = #paths
        local size = setcleanedthemesandnames(themes[i].themes, paths, themepaths, groups, join_symbol, gobd, opts,
            "themes[" .. tostring(i) .. "].",
            nameprefix .. themes[i].name .. join_symbol)
        paths[idx].size = size
        count = count + size
        themes[themes[i].name] = deepcopy(themes[i])
        themes[themes[i].name].isgroup = true
        themes[themes[i].name].name = nil
        themes[i] = nil

        ::continue::
    end

    return count
end

local function clean(opts, paths, themepaths, groups)
    local cleaned = {}
    local path = ""
    cleaned["join_symbol"] = cleansimpleopt("join_symbol", opts, { "string" }, {}, "/", path)
    cleaned["groups_open_by_default"] = cleansimpleopt("groups_open_by_default", opts, { "boolean" }, {}, false, path)
    cleaned["themes"] = cleansimpleopt("themes", opts, { "table" }, {}, {}, path)
    setcleanedthemesandnames(cleaned.themes, paths, themepaths, groups, cleaned["join_symbol"],
        cleaned["groups_open_by_default"],
        opts, path)
    cleaned["fallback"] = cleansimpleopt("fallback", opts, { "table", "string" }, {}, "habamax", path)
    if type(cleaned.fallback) == "table" then
        cleaned.fallback = setcleanedthemeandname(cleaned.fallback, "fallback")
    else
        cleaned.fallback = { colorscheme = cleaned.fallback, name = cleaned.fallback }
    end
    cleaned["fallback_setup"] = cleansimpleopt("fallback_setup", opts, { "function" }, {}, nil, path)
    cleaned["always_setup"] = cleansimpleopt("always_setup", opts, { "function" }, {}, nil, path)
    cleaned["fallback_closer"] = cleansimpleopt("fallback_closer", opts, { "function" }, {}, nil, path)
    cleaned["always_closure"] = cleansimpleopt("always_closure", opts, { "function" }, {}, nil, path)
    cleaned["make_Color_cmd"] = cleansimpleopt("make_Color_cmd", opts, { "boolean" }, {}, true, path)
    cleaned["DEBUG"] = cleansimpleopt(
        "DEBUG",
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

function M.set(opts, paths, themepaths, groups)
    config = clean(opts, paths, themepaths, groups)
end

function M.get()
    return config
end

return M
