-- config
local SEP_STRING = "|"
local M = {}

local function string_starts(String, Start)
   return string.sub(String,1,string.len(Start))==Start
end

local function string_trim(String)
    return string.match(String, "^%s*(.-)%s*$")
end

local function string_split_trimmed(String, Separator)
    local parts = {}
    for str in string.gmatch(String, "([^"..Separator.."]+)") do
            table.insert(parts, string_trim(str))
    end
    return parts
end

local function find_limit(content, starti, endi, dir)
    for rowi=starti,endi,dir
    do
        if not string_starts(string_trim(content[rowi]), SEP_STRING)
        then
            return rowi - dir
        end
    end
    return endi
end

local function cells_for_line(line)
    return string_split_trimmed(line, SEP_STRING)
end

local function get_trimed_lines(content, start_line, end_line)
    local lines = table.move(content, start_line, end_line, 1, {})
    for i, line in ipairs(lines)
    do
        lines[i] = string_trim(line)
    end
    return lines
end

local function fill_matrix(lines)
    local matrix = {}
    for row,line in ipairs(lines)
    do
        table.insert(matrix, cells_for_line(line))
    end
    return matrix
end

local function line_is_horizontal_separator(cells)
    is_hline = true
    for col, cell in ipairs(cells)
    do
        is_hline = is_hline and (string.len(cell) == 0 or cell:match("[-\\+ ]*") == cell) 
        if not is_hline
        then
            break
        end
    end
    return is_hline
end

local function print_matrix(matrix)
    max_column_len = {}
    for row, cells in ipairs(matrix)
    do
        if not line_is_horizontal_separator(cells)
        then
            for col, cell in ipairs(cells)
            do
                if max_column_len[col] == nil
                then
                    max_column_len[col] = string.len(cell)
                else
                    max_column_len[col] = math.max(max_column_len[col], string.len(cell))
                end
            end
        end
    end
    new_content = {}
    for row, cells in ipairs(matrix)
    do
        line = SEP_STRING
        if line_is_horizontal_separator(cells)
        then
            for col, max_len in ipairs(max_column_len)
            do
                pluses = string.rep("-", max_column_len[col] + 2)
                fmt = ""
                if col == #max_column_len
                then
                    fmt = "%s" .. SEP_STRING
                else
                    fmt = "%s+"
                end
                line = line .. string.format(fmt, pluses)
            end
        else
            for col, max_len in ipairs(max_column_len)
            do
                cell = cells[col] 
                if cell == nil
                then
                    spaces = string.rep(" ", max_column_len[col])
                    line = line .. string.format(" %s " .. SEP_STRING, spaces)
                else
                    spaces = string.rep(" ", max_column_len[col] - string.len(cell))
                    line = line .. string.format(" %s%s " .. SEP_STRING, cell, spaces)
                end
            end
        end
        new_content[row] = line
    end
    return new_content
end

function M.tableize()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1]
    local col = pos[2]

    local line_count = vim.api.nvim_buf_line_count(0)
    local content = vim.api.nvim_buf_get_lines(0, 0, line_count, false)

    if not string_starts(string_trim(content[row]), SEP_STRING)
    then
        return
    end

    local start_line = find_limit(content, row, 1, -1)
    local end_line = find_limit(content, row, line_count, 1)

    local table_lines = get_trimed_lines(content, start_line, end_line)
    local matrix = fill_matrix(table_lines)
    local new_content = print_matrix(matrix)

    vim.api.nvim_buf_set_lines(0, start_line-1, end_line, false, new_content)
end

return M
