local api = vim.api
local buf, win




local function center(str)
  local width = api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end




local function open_window()
  buf = api.nvim_create_buf(false, true)
  local border_buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'filetype', 'whid')

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
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
    col = col
  }

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)

  api.nvim_win_set_option(win, 'cursorline', true) -- it highlight line with the cursor on it

  -- we can add title already here, because first line will never change
  api.nvim_buf_set_lines(buf, 0, -1, false, { center('Hanoian'), '', ''})
  api.nvim_buf_add_highlight(buf, -1, 'HanoianHeader', 0, 0, -1)
end






-- Define the function to close the window
local function close_window()
	vim.api.nvim_win_close(win, true)
end






local function hanoian()
  open_window()
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":lua require('hanoian').close_window()<CR>", { silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<C-[>", ":lua require('hanoian').close_window()<CR>", { silent = true })
end






local function add_directory_to_json()
  -- Get the current file path and file name separately
  local currentFilePath = vim.fn.expand('%:p:h')
  local currentFileName = vim.fn.expand('%:p:t')

  -- Search for init.lua in current and parent directories
  local initLuaPath = vim.fn.findfile('init.lua', currentFilePath .. ';')

  if initLuaPath ~= '' then
    -- Extract the directory of the init.lua file
    local initLuaDir = vim.fn.fnamemodify(initLuaPath, ':h')
    local pathsFilePath = initLuaDir .. '/paths.txt'

    -- Open paths.txt in append mode
    local pathsFile = io.open(pathsFilePath, 'a')

    if pathsFile then
      -- Write the current file directory to paths.txt
      pathsFile:write(currentFilePath .. '\\' .. currentFileName .. '\n')
      pathsFile:close()
      print('File path added to paths.txt!')
    else
      print('Error: Unable to open paths.txt')
    end
  else
    print('Error: init.lua not found in current or parent directories')
  end
end


local function 


-- Display Hanoian in the middle
-- Create Json File if there is is none, otherwise parse it
-- Read from json file.
-- Functions
-- - Everytime open any function - read new data from json. If there is no settings, use default
-- - Toggle Hanoian File Menu - initalize
-- - Add new file to json
-- - Delete file from json if it exists




-- Check if Hanoian Json File Exists or not
local function ifHanoianJsonFileExists()
	local initFilePath = vim.fn.expand("~/.config/nvim/init.lua")
	local path = vim.fn.findfile('hanoian-settings.json', initFilePath .. ';')
	local pathCheck = vim.fn.expand(path)  -- Path to init.lua file
	local exists, _ = vim.loop.fs_stat(pathCheck)

	if exists then
		return true
	else
		return false
	end
end




-- Parse current string to get the arrays containing the path that leads to that file
local function pathStringToArrayPath(currentFilePath)
	local pathsArr = {}
	for substring in currentFilePath:gmatch("[^\\]+") do
		table.insert(pathsArr, substring)
	return pathsArr
end









local function toggleHanoianMenu()
	print("Toggle Menu")

local function openHanoianMenu()
	print("Toggle Menu")

local function closeHanoianMenu()
	print("Toggle Menu")



return {
  hanoian = hanoian,
  close_window = close_window,
  center = center,
  add_directory_to_json = add_directory_json,
  test = test,
}
