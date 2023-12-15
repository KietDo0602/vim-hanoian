
local middle_line = '║' .. string.rep(' ', win_width) .. '║'

for i=1, win_height do
	table.insert(border_lines, middle_line)
end

table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')

api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
