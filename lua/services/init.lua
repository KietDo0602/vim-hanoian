local api = vim.api

local HANOI_FILE_PATH = '~/hanoi.json'

local DEFAULT_SETTING = {
	enableNotes = "true",
	displayMode = 1,
	createMissingFile = "true"
}

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
    local function extractFilesKeys(data, path, displayName)
        for key, value in pairs(data) do
            if key == "\\files" then
				for k, v in pairs(value) do
					local temp = {
						name = k,
						path = path,
						fullPath = path .. '/' .. k,
						displayName = displayName
					}
					table.insert(keys, temp)
				end
            elseif type(value) == "table" then
				local temp_path = path .. '/' .. key
				if displayName ~= '' then
					displayName = displayName .. '/' .. key
				else
					displayName = key
				end
                extractFilesKeys(value, temp_path, displayName)
            end
        end
    end

    extractFilesKeys(obj.res, obj.rootPath, '')

    return keys
end


-- Get the deepest parent that is a projectRoot
local function getProjectRoot(jsonObj, keysArray)
    local current = jsonObj
	local res = nil

	local rootPath = ''
	local pathRes

    -- Traverse through the JSON object using the keys
    for i, key in ipairs(keysArray) do
		if rootPath == '' then
			rootPath = key
		else
			rootPath = rootPath .. '/' .. key
		end
        if current == nil then
            break
		elseif current['\\projectRoot'] then
			res = current[key]
			pathRes = rootPath
			current = current[key]
		else
			current = current[key]
        end
    end
	if current and current['\\projectRoot'] then
		res = current
		pathRes = rootPath
	end
	-- Return the json key path with projectRoot=true that is the closest parent to the children file,
	-- alongside the absolute path of the project root
	return {
		rootPath = pathRes,
		res = res
	}
end


-- Create new buffer if file doesn't exist, get current one otherwise
local function create_buffer(file)
    local buf_exists = vim.fn.bufexists(file) ~= 0
    if buf_exists then
        return vim.fn.bufnr(file)
    end

    return vim.fn.bufadd(file)
end

-- Fetch settings from hanoi.json file
local function fetchSettings()
	local path = vin.fn.expand(HANOI_FILE_PATH)
	local file = io.open(path, 'r')
	local content = file:read('*a')
	json = vim.json.decode(content) 

	return json.settings
end

-- Reset all of the data inside hanoi.json file
local function resetJSONFile()
	local path = vim.fn.expand(HANOI_FILE_PATH)
	local res = {
		path = {},
		settings = DEFAULT_SETTING
	}
	local write_file = io.open(path, 'w')
	write_file:write(encoded_json)
	write_file:close()
	return res
end


return {
	hanoi_exists = hanoi_exists,
	center = center,
	getProjectRoot = getProjectRoot,
	getChildren = getChildren,
	create_buffer = create_buffer,
}
