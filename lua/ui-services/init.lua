local api = vim.api

local CHAR_H = '─'
local CHAR_V = '│'

local CHAR_TL = '╭'
local CHAR_TR = '╮'

local CHAR_BL = '╰'
local CHAR_BR = '╯'


function center(str, width, top)
  if str == nil or str == '' then
	 str = ''
  end

  width = width - 2
  local left = math.floor(width / 2) - math.floor(string.len(str) / 2)
  local right = math.floor(width / 2) - math.floor(string.len(str) / 2)

  local left_char = CHAR_BL
  local right_char = CHAR_BR
  if top == true then
	left_char = CHAR_TL
	right_char = CHAR_TR
  end

  if width % 2 == 0 and string.len(str) % 2 == 0 then
	  return left_char .. string.rep('─', left) .. str .. string.rep('─', right) .. right_char
  end

  if width % 2 == 0 and string.len(str) % 2 == 1 then
	  return left_char .. string.rep('─', left - 1) .. str .. string.rep('─', right) .. right_char
  end

  if width % 2 == 1 and string.len(str) % 2 == 0 then
	  return left_char .. string.rep('─', left) .. str .. string.rep('─', right + 1) .. right_char
  end

  return left_char .. string.rep('─', left) .. str .. string.rep('─', right) .. right_char
end

-- Close window and buffer if it exists
local function close_window(win, buf, old_win, line, column)
	win = win or nil
	buf = buf or nil
	old_win = old_win or nil
	line = line or nil
	column = column or nil

	-- Delete if window is valid
	if win and api.nvim_win_is_valid(win) then
		api.nvim_win_close(win, true)
	end

	-- Delete if buffer is valid
	if buf and api.nvim_buf_is_valid(buf) then
		api.nvim_buf_delete(buf, { force = true })
	end

	-- If the id of old window is valid, open it again
	if old_win and old_win.win then
		api.nvim_set_current_win(old_win.win)
		api.nvim_win_set_cursor(old_win.win, {old_win.line, old_win.column})
	end
end


local function open_file(data, index)
	local selectedOption = vim.fn.line(".")
end


local function create_new_hanoian_window(hanoi_type, old_win_info, bottom_text)
  bottom_text = bottom_text or nil

  local buf = api.nvim_create_buf(false, true)

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

  -- local border_lines = { center('Hanoian' .. hanoi_type, win_width + 2, true) }
  local border_lines = { center(bottom_text, win_width + 2, true) }
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

  table.insert(border_lines, center('Hanoian' .. hanoi_type, win_width + 2, false))
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  -- api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Set to last index chosen by user
  -- api.nvim_win_set_cursor(0, {1, 1})


  vim.keymap.set('n', '<LeftMouse>', function() close_window(win, buf, old_win_info) end, { buffer = true, silent = true })


  return {
	  buffer = buf,
	  window = win
  }
end




local function displayFolders(folders, indent)
    indent = indent or 0
    local spaces = string.rep("  ", indent)

    for _, item in ipairs(folders) do
        if item.type == "folder" then
            print(spaces .. "+ " .. item.name)
            displayFolders(item.content, indent + 1)
        elseif item.type == "file" then
            print(spaces .. "- " .. item.name)
        end
    end
end



return {
	center = center,
	create_new_hanoian_window = create_new_hanoian_window,
    close_window = close_window,
	open_file = open_file,
}
