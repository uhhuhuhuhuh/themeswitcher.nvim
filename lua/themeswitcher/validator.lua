local M = {}

local validate_type = function(x, types)
	if x == nil then
		return false
	end
	local t = type(x)
	for _, expected in ipairs(types) do
		if t == expected then
			return true
		end
	end
	return false
end

local function is_array(t)
	if type(t) ~= "table" then
		return false, 0
	end
	local max_idx = 0
	for k in pairs(t) do
		if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
			return false, 0
		end
		if k > max_idx then
			max_idx = k
		end
	end
	return max_idx > 0, max_idx
end

local function validate_values(value, values, full_path, errors)
	local valid = false
	for _, allowed in ipairs(values) do
		if value == allowed then
			valid = true
			break
		end
	end
	if not valid then
		table.insert(
			errors,
			string.format(
				"Invalid value for %s: '%s' not in [%s]",
				full_path,
				tostring(value),
				table.concat(values, ", ")
			)
		)
	end
	return valid
end

local function validate_array_item(item, i, rule, full_path, errors, validate_config_func)
	local item_path = full_path .. "[" .. i .. "]"

	if item == nil then
		if rule.default ~= nil then
			return rule.default
		end
		return nil
	end

	-- Create a temporary guide for this item
	local item_guide = {}
	for k, v in pairs(rule) do
		item_guide[k] = v
	end

	-- Don't process dict_valid at the item level
	item_guide.dict_valid = nil
	item_guide.item_valid = nil

	-- Validate the item as a single field
	local item_errors = {}

	if item_guide.types ~= nil and not validate_type(item, item_guide.types) then
		table.insert(
			item_errors,
			string.format(
				"Invalid type for %s: got %s, expected one of %s",
				item_path,
				type(item),
				table.concat(item_guide.types, ", ")
			)
		)
	end

	if #item_errors == 0 and item_guide.values ~= nil then
		validate_values(item, item_guide.values, item_path, item_errors)
	end

	-- If there are errors, add them and return
	for _, err in ipairs(item_errors) do
		table.insert(errors, err)
	end
	if #item_errors > 0 then
		return nil
	end

	-- Handle nested validation for tables
	if type(item) == "table" then
		if rule.dict_valid ~= nil then
			local sub_result = validate_config_func(item, rule.dict_valid, item_path)
			for _, err in ipairs(sub_result.errors) do
				table.insert(errors, err)
			end
			return sub_result.cleaned
		elseif rule.item_valid ~= nil then
			local sub_result = validate_config_func({ item = item }, { item = rule.item_valid }, item_path)
			for _, err in ipairs(sub_result.errors) do
				table.insert(errors, err)
			end
			return sub_result.cleaned.item or item
		end
	end

	return item
end

local function validate_array(value, rule, full_path, errors, validate_config_func)
	local array_check, max_idx = is_array(value)

	if not array_check then
		table.insert(errors, string.format("%s should be an array", full_path))
		return nil
	end

	if max_idx == 0 then
		return {}
	end

	local validated_items = {}
	for i = 1, max_idx do
		local item = value[i]
		local validated = validate_array_item(item, i, rule, full_path, errors, validate_config_func)

		if validated ~= nil then
			validated_items[i] = validated
		elseif rule.default ~= nil then
			validated_items[i] = rule.default
		end
	end

	return validated_items
end

local function validate_dict(value, rule, full_path, errors, validate_config_func)
	local array_check = is_array(value)

	if array_check then
		table.insert(errors, string.format("Invalid structure for %s: expected dictionary, got array", full_path))
		return nil
	end

	local sub_result = validate_config_func(value, rule.dict_valid, full_path)
	for _, err in ipairs(sub_result.errors) do
		table.insert(errors, err)
	end

	return sub_result.cleaned
end

local function validate_field(key, rule, value, full_path, errors, cleaned, validate_config_func)
	if value == nil then
		if rule.required == true then
			table.insert(errors, "Required field missing: " .. full_path)
			return false
		end
		if rule.default ~= nil then
			cleaned[key] = rule.default
		end
		return true
	end

	if rule.types ~= nil and not validate_type(value, rule.types) then
		table.insert(
			errors,
			string.format(
				"Invalid type for %s: got %s, expected one of %s",
				full_path,
				type(value),
				table.concat(rule.types, ", ")
			)
		)
		return false
	end

	if rule.values ~= nil then
		validate_values(value, rule.values, full_path, errors)
	end

	local processed = false

	if rule.dict_valid ~= nil and type(value) == "table" then
		local dict_result = validate_dict(value, rule, full_path, errors, validate_config_func)
		if dict_result ~= nil then
			cleaned[key] = dict_result
			processed = true
		end
	end

	if not processed and rule.item_valid ~= nil and type(value) == "table" then
		local array_result = validate_array(value, rule.item_valid, full_path, errors, validate_config_func)
		if array_result ~= nil then
			cleaned[key] = array_result
			processed = true
		end
	end

	if not processed and value ~= nil then
		cleaned[key] = value
	end

	return true
end

local function validate_config(user_config, guide, path)
	local errors = {}
	local cleaned = {}
	path = path or ""

	for key, rule in pairs(guide) do
		local full_path = path == "" and key or path .. "." .. key
		local value = user_config[key]

		validate_field(key, rule, value, full_path, errors, cleaned, validate_config)
	end

	return { cleaned = cleaned, errors = errors }
end

function M.parse_config(user_config, guide)
	local result = validate_config(user_config or {}, guide)

	if #result.errors > 0 then
		error("Config validation failed:\n" .. table.concat(result.errors, "\n"))
	end

	return result.cleaned
end

return M
