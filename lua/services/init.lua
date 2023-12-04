local api = vim.api


local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end


local function hanoi_exists()
	local config_dir = vim.fn.stdpath('config')
	local init_lua_path = config_dir .. '/hanoi.json'

	if file_exists(init_lua_path) then
		print("init.lua exists in Neovim config directory.")
		return true
	else
		print("init.lua does not exist in Neovim config directory.")
		return false
	end
end


local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end



-- Get all keys inside JSON object
local function getChildren(obj)
	if obj == nil then
		 return nil
	end
    local keys = {}

    local function extractFilesKeys(data)
        for key, value in pairs(data) do
            if key == "\\files" then
				for k, v in pairs(value) do
					table.insert(keys, k)
				end
            elseif type(value) == "table" then
                extractFilesKeys(value)
            end
        end
    end

    extractFilesKeys(obj)

    return keys
end


-- Get the closest parent that is a projectRoot
local function getProjectRoot(jsonObj, keysArray)
    local current = jsonObj
	local res = nil

    -- Traverse through the JSON object using the keys
    for i, key in ipairs(keysArray) do
        if current == nil then
            break
		elseif current['\\projectRoot'] and current['\\projectRoot'] == "true" then
			res = current
		else
			current = current[key]
        end
    end
	-- Return the json key path with projectRoot=true that is the closest parent to the children file
	return res
end




return {
	file_exists = file_exists,
	hanoi_exists = hanoi_exists,
	center = center,
	getProjectRoot = getProjectRoot,
	getChildren = getChildren,
}
