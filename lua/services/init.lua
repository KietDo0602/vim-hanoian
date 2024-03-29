local api = vim.api

local HANOI_FILE_PATH = '~/hanoi.json'

local DEFAULT_SETTING = {
	enableNotes = "true",
	displayMode = 1,
	createMissingFile = "true"
}


function hanoi_exists()
	local path = vin.fn.expand(HANOI_FILE_PATH)
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


function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep('─', shift) .. str .. string.rep('─', shift) 
end


-- Get all keys inside JSON object
function getChildren(obj)
	if obj == nil then
		 return nil
	end

    local keys = {}
    local function extractFilesKeys(data, fullPath, relativePath)
		if data == nil then
			return nil
		end
        for key, value in pairs(data) do
            if key == "\\files" then
				for k, v in pairs(value) do
					local tempRelativePath = k
					if relativePath ~= '' then
						tempRelativePath = relativePath .. '/' .. k
					end

					local temp = {
						fileName = k,
						relativeFilePath = tempRelativePath,
						fullFilePath = fullPath .. '/' .. k
					}
					table.insert(keys, temp)
				end
            elseif type(value) == "table" then
				local tempFullPath = fullPath .. '/' .. key

				local tempRelativePath = key
				if relativePath ~= '' then
					tempRelativePath = relativePath .. '/' .. key
				end

                extractFilesKeys(value, tempFullPath, tempRelativePath)
            end
        end
    end

    extractFilesKeys(obj.res, obj.rootPath, '')

    return keys
end


-- Get the deepest parent that is a projectRoot
function getProjectRoot(json, keysArray)
    local current = json
	local res = nil

	local rootPath = ''
	local pathRes
	local rootFolderName = nil
	local last_key = nil

    -- Traverse through the JSON object using the keys
    for i, key in ipairs(keysArray) do
		if rootPath == '' then
			rootPath = key
		else
			rootPath = rootPath .. '/' .. key
		end

        if current == nil then
            break
		elseif current[key] and current[key]['\\projectRoot'] then
			res = current[key]
			pathRes = rootPath
			rootFolderName = key
        end

		current = current[key]
		last_key = key
    end
	if current and current['\\projectRoot'] then
		res = current
		pathRes = rootPath
		rootFolderName = last_key
	end

	-- Return the json key path with projectRoot=true that is the closest parent to the children file,
	-- alongside the absolute path of the project root
	return {
		rootPath = pathRes,
		res = res,
		name = rootFolderName
	}
end


-- Create new buffer if file doesn't exist, get current one otherwise
function create_buffer(file)
    local buf_exists = vim.fn.bufexists(file) ~= 0
    if buf_exists then
        return vim.fn.bufnr(file)
    end

    return vim.fn.bufadd(file)
end


function pathToTable(path)
	if path == '' or path == nil then
		return nil
	end

	local res = {}
	for substring in path:gmatch("[^\\]+") do
		table.insert(res, substring)
	end

	return res
end


-- Fetch json from hanoi.json file
function getHanoiJSON()
	local path = vim.fn.expand(HANOI_FILE_PATH)
	local file = io.open(path, 'r')

	if file then
		local content = file:read('*a')

		local success, json = pcall(vim.json.decode, content)

		if success then
			-- If the decoding was successful, return it
			return json
		end
	end

	local res = {
		paths = {},
		settings = DEFAULT_SETTING
	}
	res.paths['\\projectRoot'] = "true"

	return res
end


-- Reset all of the data inside hanoi.json file
function writeToEmptyJSONFile()
	local res = {
		paths = {},
		settings = DEFAULT_SETTING
	}
	res.paths['\\projectRoot'] = "true"

	local path = vim.fn.expand(HANOI_FILE_PATH)
	local write_file = io.open(path, 'w')
	local json = vim.json.encode(res)
	write_file:write(json)
	write_file:close()

	return res
end


function getAllRootFolder(json)
    local roots = {}

    local function getRootHelper(data, fullPath)
        for key, value in pairs(data) do
            if value and value['\\projectRoot'] then
				local tempFullPath = fullPath .. '/' .. key
				if fullPath == '' then
					tempFullPath = key
				end

				local elem = {
					name = key,
					path = tempFullPath
				}
				table.insert(roots, elem)
			end

            if type(value) == "table" and key ~= "\\files"  then
				local tempFullPath = fullPath .. '/' .. key
				if fullPath == '' then
					tempFullPath = key
				end
				getRootHelper(value, tempFullPath)
            end
        end
    end

	getRootHelper(json, '')

	return roots
end


function sort(arr, key)
    table.sort(arr, function(a, b)
        return tostring(a[key]) < tostring(b[key])
    end)
    return arr
end

-- Get name of the directory / file at the end of a path
-- (e.g. folder/file1 => file1)
function getName(inputString)
	if inputString == nil or inputString == '' then
		return ''
	end

    local temp = ''
    for substring in inputString:gmatch("[^\\]+") do
		temp = substring
    end
    return temp
end


return {
	hanoi_exists = hanoi_exists,
	center = center,
	getProjectRoot = getProjectRoot,
	getChildren = getChildren,
	create_buffer = create_buffer,
	getHanoiJSON = getHanoiJSON,
	writeToEmptyJSONFile = writeToEmptyJSONFile,
	pathToTable = pathToTable,
	getAllRootFolder = getAllRootFolder,
	sort = sort,
	getName = getName,
}
