 services = require('services')

local api = vim.api

local buf
local win

local global_line_number = 0
local global_column_number = 0
local temp_buf = nil
local old_before_win = nil
local buf_name = nil

local pathData = nil



local function close_window()
	-- Delete buffer containing the Hanoian Menu
	if buf and api.nvim_buf_is_valid(buf) then
		api.nvim_buf_delete(buf, { force = true })
	end

	-- Return to the old window before
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
	  -- Get the current file path and file name separately
	local currentFilePath = vim.fn.expand('%:p:h')
	local currentFileName = vim.fn.expand('%:p:t')

	local pathsArr = {}
	for substring in currentFilePath:gmatch("[^\\]+") do
		table.insert(pathsArr, substring)
	end

	local path = vim.fn.expand('~/.config/nvim-data/hanoi.json')
	local file = io.open(path, 'r')
	
	if file then
		local jsonFileContent = file:read('*a')
		
		local decodedJson = vim.json.decode(jsonFileContent).paths

		local rootDirectory = services.getProjectRoot(decodedJson, pathsArr)

		local allChildren = services.getChildren(rootDirectory.res, rootDirectory.rootPath)

		file:close()

		return allChildren
	else
		local newFile = io.open(path, 'w')

		if newFile then
			local initialContent = {
				paths = {},
				settings = {}
			}
			local final_json = vim.json.encode(initialContent)
			newFile:write(final_json)
			newFile:close()
			-- Retry after creating json file
			file:close()
		else
			print("Unable to create file at " .. path)
		end

		return nil
	end
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
  api.nvim_buf_set_option(buf, 'filetype', 'hanoian')
  api.nvim_buf_set_option(buf, "buftype", "acwrite")
  api.nvim_buf_set_option(buf, "bufhidden", "delete")

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.6 - 4)
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

  local new_width = (win_width - 7) / 2
  local border_lines = { '╭' .. string.rep('─', new_width) .. "Hanoian" .. string.rep('─',  new_width + 1) .. '╮' }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'

  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end

  table.insert(border_lines, '╰' .. string.rep('─', win_width) .. '╯')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)

  api.nvim_win_set_option(win, 'cursorline', true) -- it highlight line with the cursor on it
  api.nvim_win_set_option(win, "number", true)

  -- Add directory to the menu
  pathData = Return_Menu_Data()
  local childrenContentObject = pathData

  for i, value in ipairs(childrenContentObject) do
	api.nvim_buf_set_lines(buf, i - 1, -1, false, { value.name })
  end

  -- api.nvim_buf_add_highlight(buf, -1, 'HanoianHeader', 0, 0, -1)
  api.nvim_buf_set_keymap(buf, 'n', '<ESC>', '<Cmd>lua require("hanoian").hanoian()<CR>', { silent = true })
  api.nvim_buf_set_keymap(buf, 'n', '<CR>', ":lua require'hanoian'.open_file()<CR>", {
	silent = true,
	nowait = true
  })
  print("Open Hanoian Menu!")
end

local function open_file()
	-- Get file selected by the user
	local current_column = vim.fn.line(".")
	local pathToFile = pathData[current_column].path
	local fileName = pathData[current_column].name 
	local fullFilePath = pathToFile .. '/' .. fileName

	local currentBuffer = services.create_buffer(fullFilePath)
	close_window()
	api.nvim_set_current_buf(currentBuffer)
	print('Editing ' .. fileName)
end



-- Set current directory as project root
local function set_project_root()
	local directory_path = vim.fn.getcwd()

	local pathsArr = {}
	for substring in directory_path:gmatch("[^\\]+") do
		table.insert(pathsArr, substring)
	end

	local path = vim.fn.expand('~/.config/nvim-data/hanoi.json')
	local file = io.open(path, 'r')
	
	if file then
		local jsonFileContent = file:read('*a')
		
		local decodedJson = vim.json.decode(jsonFileContent)
		local json = decodedJson.paths

		local current = json
		for index, value in ipairs(pathsArr) do
			if current[value] == nil then
				current[value] = {}
			end
			current = current[value]
		end
		if current ~= nil then
			current["\\projectRoot"] = "true"
			local encoded_json = vim.json.encode(decodedJson) 
			local final_file = io.open(path, 'w')
			final_file:write(encoded_json)
			final_file:close()
		end
	end
end

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
	local pathsArr = {}
	for substring in currentFilePath:gmatch("[^\\]+") do
		table.insert(pathsArr, substring)
	end

	local cursor_pos = api.nvim_win_get_cursor(0)
	local line_number = cursor_pos[1]
	local column_number = cursor_pos[2]

	local path = vim.fn.expand('~/.config/nvim-data/hanoi.json')
	local file = io.open(path, 'r')

	if file then
		local content = file:read('*a')
		file:close()

		local json
		if content == nil then
			json = {}
		else
			json = vim.json.decode(content) 
		end

		if json.paths == nil then
			json.paths = {}
		end
		if json.settings == nil then
			json.settings = {}
		end

		local current = json.paths
		for i, path in ipairs(pathsArr) do
			if current[path] == nil then
				current[path] = {}
			end

			if i == #pathsArr then
				if current[path]['\\files'] == nil then
					local new_file_content = {}
					new_file_content.marker = line_number .. ':' .. column_number
					new_file_content.notes = ""
					current[path] = {}
					current = current[path]
					current['\\files'] = {}
					current = current['\\files']
					current[currentFileName] = new_file_content
					print(currentFileName .. ' added!')
					break
				else
					local new_file_content = {}
					new_file_content.marker = line_number .. ':' .. column_number
					new_file_content.notes = ""
					current[path]['\\files'][currentFileName] = new_file_content
				end
			end
			current = current[path]
		end

		local encoded_json = vim.json.encode(json) 

		local final_file = io.open(path, 'w')
		final_file:write(encoded_json)
		final_file:close()
	else
		-- File doesn't exist, create it and write "Hello World" to it
		local newFile = io.open(path, 'w')
		if newFile then
			local initialContent = {
				paths = {},
				settings = {}
			}
			local final_json = vim.json.encode(initialContent)
			newFile:write(final_json)
			newFile:close()
			-- Retry after creating json file
			file:close()
			add_directory()
		else
			print("Unable to create file at " .. path)
		end
	end
end

return {
	hanoian = hanoian,
	open_window = open_window,
	close_window = close_window,
	add_directory = add_directory,
	set_project_root = set_project_root,
	open_file = open_file,
}

