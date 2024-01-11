local api = vim.api

local services = require('services')
local settings = require('settings')
local ui = require('ui-services')


local cursorWindowIndex = 1

local hanoi = nil

local currentRoot = nil


-- Open file at the curent line number that the cursor is on
function open_file(data, hanoian, old_win_info)
	-- Get file selected by the user
	local current_column = vim.fn.line(".")

	if data == nil or data[current_column] == nil then
		print('There are no files to open :(')
		return
	end

	local fileName = data[current_column].fileName 
	local fullFilePath = data[current_column].fullFilePath

	local currentBuffer = services.create_buffer(fullFilePath)

	ui.close_window(hanoian.window, hanoian.buffer, old_win_info)
	hanoi = nil

	api.nvim_set_current_buf(currentBuffer)

	cursorWindowIndex = current_column

	print('Opening ' .. fileName)
end


-- Open Menu containing all of the files in project root
function open_window()
	local old_win = api.nvim_get_current_win()
	local cursor_pos = api.nvim_win_get_cursor(0)
	local line_number = cursor_pos[1]
	local column_number = cursor_pos[2]
	local currentFilePath = currentRoot or vim.fn.expand('%:p:h')
	currentFilePath = currentFilePath:gsub('/', '\\')
	local currentCWD = currentRoot or vim.fn.getcwd()
	currentCWD = currentCWD:gsub('/', '\\')
	local projectName = services.getName(currentCWD)

	local old_win_info = {
		win = old_win,
		line = line_number,
		column = column_number,
	}

	local hanoian = ui.create_new_hanoian_window('.Files', old_win_info, projectName)

	
	local json = services.getHanoiJSON()

	if json == nil then
		services.writeToEmptyJSONFile()
		json = services.getHanoiJSON()
	end

	-- Get menu display settings
	local menuDisplayType = settings.GetDisplayPathType()

	local pathsTable = services.pathToTable(currentFilePath)

	local roots = services.getProjectRoot(json.paths, pathsTable) 

	local data = services.getChildren(roots)

	local displayKey = 'relativeFilePath'
	if menuDisplayType == 2 then
		displayKey = 'fileName'
	elseif menuDisplayType == 3 then
		displayKey = 'fullFilePath'
	end

	data = services.sort(data, displayKey)

	if data and #data >= 1 then
	  for i, value in ipairs(data) do
		local text = value[displayKey]
		api.nvim_buf_set_lines(hanoian.buffer, i - 1, -1, false, { text })
	  end
	end

	vim.keymap.set('n', '<CR>', function() open_file(data, hanoian, old_win_info) end, { buffer = true, silent = true })

	vim.keymap.set('n', '<ESC>', function() ui.close_window(hanoian.window, hanoian.buffer, old_win_info) hanoi = nil end, { buffer = true, silent = true })

	print("Open Hanoian Menu!")

	return {
		res = hanoian,
		old = old_win_info
	}
end


-- Toggle Hanoi.Files Menu
function hanoi_toggle_file()
	if hanoi == nil then
		set_project_root(nil, false)
		hanoi = open_window()
		return
	end

	ui.close_window(hanoi.res.window, hanoi.res.buffer, hanoi.old, hanoi.old.line, hanoi.old.column)
	hanoi = nil
end


-- Set current cwd as project root
function set_project_root(filePath, printLog)
	filePath = filePath or nil
	printLog = printLog or false

	if filePath ~= nil then
		filePath = filePath:gsub('/', '\\')
	end

	local directory_path = filePath or vim.fn.getcwd()
	local path = vim.fn.expand('~/hanoi.json')

	local pathsTable = services.pathToTable(directory_path)

	-- Get current json content inside hanoi.json
	local json = services.getHanoiJSON()

	-- Create new hanoi.json if an error occured opening the json
	if json == nil then
		return services.writeToEmptyJSONFile()
	end

	local current = json.paths
	for index, value in ipairs(pathsTable) do
		if current[value] == nil then
			current[value] = {}
		elseif index == #pathsTable then
			current = current[value]
			current["\\projectRoot"] = "true"
			local encoded_json = vim.json.encode(json) 
			local final_file = io.open(path, 'w')
			final_file:write(encoded_json)
			final_file:close()
			if printLog == true then
				print(directory_path .. " added as project root!")
			end
			return
		end
		current = current[value]
	end
	if current ~= nil then
		current["\\projectRoot"] = "true"
		local encoded_json = vim.json.encode(json) 
		local final_file = io.open(path, 'w')
		final_file:write(encoded_json)
		final_file:close()
		if printLog == true then
			print(directory_path .. " added as project root!")
		end
		return
	end

	if printLog == true then
		print('Error adding ' .. directory_path .. ' as project root :(')
	end
end


-- Add file
function add_file()
	local currentFilePath = vim.fn.expand('%:p:h')
	local currentFileName = vim.fn.expand('%:p:t')

	local pathsArr = services.pathToTable(currentFilePath)

	local cursor_pos = api.nvim_win_get_cursor(0)
	local line_number = cursor_pos[1]
	local column_number = cursor_pos[2]

	local json = services.getHanoiJSON()

	if json == nil then
		services.writeToEmptyJSONFile()
		json = services.getHanoiJSON()
	end

	local current = json.paths

	for i, folder in ipairs(pathsArr) do
		if current and current[folder] == nil then
			current[folder] = {}
		end

		if i == #pathsArr then
			if current[folder]['\\files'] == nil then
				local new_file_content = {}
				new_file_content.marker = line_number .. ':' .. column_number
				new_file_content.notes = ""
				current[folder] = {}
				current = current[folder]
				current['\\files'] = {}
				current = current['\\files']
				current[currentFileName] = new_file_content
				print(currentFileName .. ' added!')
				break
			else
				local new_file_content = {}
				new_file_content.marker = line_number .. ':' .. column_number
				new_file_content.notes = ""
				current[folder]['\\files'][currentFileName] = new_file_content
				print(currentFileName .. ' added!!')
				break
			end
		end

		current = current[folder]
	end

	local encoded_json = vim.json.encode(json) 

	local path = vim.fn.expand('~/hanoi.json')
	local final_file = io.open(path, 'w')
	final_file:write(encoded_json)
	final_file:close()
end


-- Remove file
function remove_file()
	local currentFilePath = vim.fn.expand('%:p:h')
	local currentFileName = vim.fn.expand('%:p:t')

	local pathsArr = services.pathToTable(currentFilePath)

	local cursor_pos = api.nvim_win_get_cursor(0)
	local line_number = cursor_pos[1]
	local column_number = cursor_pos[2]

	local json = services.getHanoiJSON()

	if json == nil then
		services.writeToEmptyJSONFile()
		json = services.getHanoiJSON()
	end

	local current = json.paths
	for i, folder in ipairs(pathsArr) do
		if current and current[folder] == nil then
			print('There are no files to remove')
			break
		end

		if i == #pathsArr then
			if current[folder]['\\files'] == nil then
				print('There are no files to remove!!')
			else
				local json_object = {}
				local temp = current[folder]['\\files']
				for key, value in ipairs(temp) do
					if key ~= currentFileName then
						json_object[key] = value
					end
				end
				current[folder]['\\files'] = json_object
				print(currentFileName .. ' removed!!')
			end
			break
		end
		current = current[folder]
	end

	local encoded_json = vim.json.encode(json) 

	local path = vim.fn.expand('~/hanoi.json')
	local final_file = io.open(path, 'w')
	final_file:write(encoded_json)
	final_file:close()
end


function open_projects_window()
	local old_win = api.nvim_get_current_win()
	local cursor_pos = api.nvim_win_get_cursor(0)
	local line_number = cursor_pos[1]
	local column_number = cursor_pos[2]

	local old_win_info = {
		win = old_win,
		line = line_number,
		column = column_number,
	}

	local hanoian = ui.create_new_hanoian_window('.Projects', old_win_info)
	
	local json = services.getHanoiJSON()
	local data = services.getAllRootFolder(json.paths) 

	if data and #data >= 1 then
	  for i, value in ipairs(data) do
		local text = value.path
		api.nvim_buf_set_lines(hanoian.buffer, i - 1, -1, false, { text })
	  end
	end

	local function set_current_root(data)
		local current_column = vim.fn.line('.')
		local rootName = data[current_column].name 
		local fullRootPath = data[current_column].path

		ui.close_window(hanoian.window, hanoian.buffer, old_win_info)		
		
		currentRoot = fullRootPath 
		print(currentRoot .. ' set as current project!!')
	end

	api.nvim_buf_set_option(hanoian.buffer, 'modifiable', false)
	-- Set buffer to unmodifiable after adding information
    vim.keymap.set('n', '<CR>', function() set_current_root(data) end, { buffer = true, silent = true })
	vim.keymap.set('n', '<ESC>', function() ui.close_window(hanoian.window, hanoian.buffer, old_win_info) data = nil end, { buffer = true, silent = true })
	print('Open Hanoi.Projects Window!')
end


function open_notes()

end



return {
	hanoi_toggle_file=hanoi_toggle_file,
	open_window = open_window,
	open_file = open_file,
	add_file = add_file,
	remove_file = remove_file,
	open_projects_window = open_projects_window,
	set_project_root = set_project_root,
}

