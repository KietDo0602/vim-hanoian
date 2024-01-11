

-- Function to format JSON without external tools
local function format_json(json_str)
    local function format_helper(text, current_indent)
        local indent = "    " -- You can change the indentation as needed
        local i = 1
        local output = ""
        local length = #text

        while i <= length do
            local char = text:sub(i, i)
            if char == "{" or char == "[" then
                output = output .. char .. "\n" .. string.rep(indent, current_indent + 1)
                current_indent = current_indent + 1
            elseif char == "}" or char == "]" then
                output = output .. "\n" .. string.rep(indent, current_indent - 1) .. char
                current_indent = current_indent - 1
            elseif char == "," then
                output = output .. char .. "\n" .. string.rep(indent, current_indent)
            else
                output = output .. char
            end
            i = i + 1
        end

        return output
    end

    local success, parsed = pcall(vim.fn.json_decode, json_str)
    if not success then
        return nil, "Invalid JSON format"
    end

    local formatted = format_helper(vim.fn.json_encode(parsed), 0)
    return formatted
end

-- -- Example usage
-- local json_data = '{"key": "value", "nested": {"inner_key": "inner_value"}}'
-- local formatted, err = format_json(json_data)

-- if err then
--     print("Error:", err)
-- else
--     print(formatted)
-- end


return {
	format_json = format_json,
}
