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

	if json and json.settings and json.settings.menuDisplayType then
		return json.settings.menuDisplayType
	end

	return 1
end

function setDisplayPathType(num)
	local json = services.getHanoiJSON()
end

return {
	GetDisplayPathType = GetDisplayPathType,
}

