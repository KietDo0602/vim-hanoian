local services = require('services')
local settings = require('settings')
local ui = require('ui-services')

local api = vim.api

local buf
local win

local temp_buf = nil
local global_line_number = 0
local global_column_number = 0

local old_before_win = nil
local buf_name = nil

local pathData = nil
local cursorWindowIndex = 1

local currentRoot = nil

local function close_window()
	-- Delete window containing the Hanoian Menu
	if win and api.nvim_win_is_valid(win) then
		api.nvim_win_close(win, true)
	end

	-- Delete buffer containing the Hanoian Menu
	if buf and api.nvim_buf_is_valid(buf) then
		api.nvim_buf_delete(buf, { force = true })
	end

	-- Return to the old window
	if old_before_win ~= nil then
		api.nvim_set_current_win(old_before_win)
		api.nvim_win_set_cursor(old_before_win, {global_line_number, global_column_number})
	end

	old_before_win = nil
	win = nil
	buf = nil
	temp_buf = nil
	global_line_number = nil
	global_column_number = nil
	buf_name = nil
end



local function Return_Menu_Data()
	-- Get the current file path
	local currentFilePath = vim.fn.expand('%:p:h')
	-- Get the file name
	local currentFileName = vim.fn.expand('%:p:t')

	-- Extract each folder from file path and add to table
	local pathsTable = services.pathToTable(currentFilePath)

	-- Get current json content inside hanoi.json
	local json = services.getHanoiJSON()

	-- Create new hanoi.json if an error occured opening the json
	if json == nil then
		return services.writeToEmptyJSONFile()
	end

	-- Get the json object of the root directory
	local rootDirectoryJSON = services.getProjectRoot(json.paths, pathsTable)
	
	-- Get all of the files inside root directory json
	local res = services.getChildren(rootDirectoryJSON)

	return {
		res = res,
		rootDirectoryName = rootDirectoryJSON.name
	}
end
 

local function open_window()
  old_before_win = api.nvim_get_current_win()
  temp_buf = api.nvim_get_current_buf()
  local buf_info = vim.fn.getbufinfo(temp_buf)

  if #buf_info >= 1 then
	  buf_name = buf_info[1].name
	  global_line_number = buf_info[1].lnum
	  global_column_number = 1
  end

  -- Get the current buffer's information before opening a new one
  buf = api.nvim_create_buf(false, true)

  local border_buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'filetype', 'nvim-oldfile')
  api.nvim_buf_set_option(buf, "buftype", "acwrite")
  api.nvim_buf_set_option(buf, "bufhidden", "delete")


  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.3 - 4)
  local win_width = math.ceil(width * 0.6)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  local border_lines = { ui.center('Hanoian.files', win_width + 2, true) }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'

  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end

  local border_win = api.nvim_open_win(border_buf, true, border_opts)

  win = api.nvim_open_win(buf, true, opts)

  api.nvim_win_set_option(win, 'winhighlight', 'Normal:NormalFloat')

  -- Set the border color
  vim.cmd("highlight NormalFloat guibg=black guifg=white")

  -- Set the background color
  vim.cmd("highlight NormalFloat guibg=black guifg=white")

  -- Set the text color
  vim.cmd("highlight NormalFloat guibg=black guifg=white")

  api.nvim_win_set_option(win, 'cursorline', true) -- this highlights the line with the cursor on it
  api.nvim_win_set_option(win, "number", true)
  api.nvim_win_set_option(win, 'wrap', false)

  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)

  -- Add directory to the menu
  pathData = Return_Menu_Data()
  local rootDirectoryName = pathData.rootDirectoryName 

  -- Get menu display settings
  local menuDisplayType = settings.GetDisplayPathType()

  local childrenContentObject = pathData.res

  if childrenContentObject ~= nil and #childrenContentObject >= 1 then
	  for i, value in ipairs(childrenContentObject) do
		local item_display_text = value.relativeFilePath
		api.nvim_buf_set_lines(buf, i - 1, -1, false, { item_display_text })
	  end
  end


  -- Add root folder name to the bottom of the window
  table.insert(border_lines, ui.center(rootDirectoryName, win_width + 2, false))
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  -- Set buffer to unmodifiable
  api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Set to last index chosen by user
  api.nvim_win_set_cursor(0, {cursorWindowIndex, 1})


  api.nvim_buf_set_keymap(buf, 'n', '<ESC>', "<Cmd>lua require('hanoian').hanoian()<CR>", { silent = true })
  api.nvim_buf_set_keymap(buf, 'n', '<CR>', ":lua require('hanoian').open_file()<CR>", {
	silent = true,
	nowait = true
  })
  api.nvim_buf_set_keymap(buf, 'n', '<LeftMouse>', ":lua require'hanoian'.close_window()<CR>", {
	silent = true,
	nowait = true
  })

  print("Open Hanoian Menu!")
end


-- Open file at the curent line number that the cursor is on
local function open_file()
	-- Get file selected by the user
	local current_column = vim.fn.line(".")
	local fileName = pathData.res[current_column].fileName 
	local fullFilePath = pathData.res[current_column].fullFilePath

	local currentBuffer = services.create_buffer(fullFilePath)
	close_window()
	api.nvim_set_current_buf(currentBuffer)
	cursorWindowIndex = current_column
	print('Editing ' .. fileName)
end



-- Set current directory as project root
local function set_project_root()
	local directory_path = vim.fn.getcwd()
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
			print(directory_path .. " added as project root!")
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
		print(directory_path .. " added as project root!!")
		return
	end
	print('Error adding ' .. directory_path .. ' as project root :(')
end


-- Toggle Hanoian Menu
local function hanoian()
	if win and api.nvim_win_is_valid(win) then
		close_window()
		return
	end
	open_window()
end



local function add_directory()
	local currentFilePath = vim.fn.expand('%:p:h')
	local currentFileName = vim.fn.expand('%:p:t')

	local pathsArr = services.pathToTable(currentFilePath)

	local cursor_pos = api.nvim_win_get_cursor(0)
	local line_number = cursor_pos[1]
	local column_number = cursor_pos[2]

	local path = vim.fn.expand('~/hanoi.json')
	local json = services.getHanoiJSON()

	local current = json.paths
	for i, folder in ipairs(pathsArr) do
		if current[folder] == nil then
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

	local final_file = io.open(path, 'w')
	final_file:write(encoded_json)
	final_file:close()
end



local function open_roots_window()
	local old_win = api.nvim_get_current_win()
	local cursor_pos = api.nvim_win_get_cursor(0)
	local line_number = cursor_pos[1]
	local column_number = cursor_pos[2]

	local old_win_info = {
		win = old_win,
		line = line_number,
		column = column_number,
	}

	local hanoian = ui.create_new_hanoian_window('.Roots', old_win_info)
	
	local json = services.getHanoiJSON()
	local data = services.getAllRootFolder(json.paths) 

	if data and #data >= 1 then
	  for i, value in ipairs(data) do
		local text = value.path
		api.nvim_buf_set_lines(hanoian.buffer, i - 1, -1, false, { text })
	  end
	end

	local function set_current_root()
		local current_column = vim.fn.line(".")
		local rootName = data[current_column].name 
		local fullRootPath = data[current_column].path

		ui.close_window(hanoian.window, hanoian.buffer, nil, nil, nil)
		
		currentRoot = fullRootPath 

		print(rootName .. ' folder set as new project root!')
	end

	-- Set buffer to unmodifiable after adding information
    vim.keymap.set('n', '<CR>', function() set_current_root() end, { buffer = true, silent = true })
	api.nvim_buf_set_option(hanoian.buffer, 'modifiable', false)
end


return {
	hanoian = hanoian,
	open_window = open_window,
	close_window = close_window,
	add_directory = add_directory,
	set_project_root = set_project_root,
	open_file = open_file,
	getSettings = getSettings,
	open_roots_window = open_roots_window,
}

