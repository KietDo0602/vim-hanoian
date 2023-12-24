local services = require('../services')

local api = vim.api

local DEFAULT_SETTING = {
	enableNotes = "true",
	displayMode = 1,
	createMissingFile = "true"
}


-- Return user-preferred path types
-- 1. (Default) Relative Path Type (example: project/file.txt)
-- 2. Absolute Path Type (example: C:/Documents/project/file.txt)
-- 3. File name only (example: file.txt)
local function GetDisplayPathType()
	local json = services.getHanoiJSON()
	if json == nil or json.settings == nil then
		return 1
	end

	if json.settings.MenuDisplayType ~= nil then
		return json.settings.MenuDisplayType
	end

	return 1
end





return {
	GetDisplayPathType = GetDisplayPathType,
}

