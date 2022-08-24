-- config
local SEP_STRING = "|"
local M = {}

local function string_utf8_len(String)
    local len = 0
    local i = 1
    local slen = string.len(String)
    while(i <= slen)
    do
        b = String:byte(i)
        if b < 128 then
            len = len + 1
            i = i + 1
        elseif b >= 240 then
            len = len + 1
            i = i + 4
        elseif b >= 224 then
            len = len + 1
            i = i + 3
        elseif b >= 192 then
            len = len + 1
            i = i + 2
        end
    end
    return len
end

local function string_starts(String, Start)
   return string.sub(String,1,string.len(Start))==Start
end

local function is_whitespace(c)
    return c == 0x20 or (c >= 0x09 and c <= 0x0d)
end

local function string_trim_stats(String)
    local slen = string.len(String)
    local leftlim = nil
    local rightlim = nil

    for i=1,slen
    do
        if not is_whitespace(string.byte(String, i))
        then
            leftlim = i
            break
        end
    end

    for i=slen,1,-1
    do
        if not is_whitespace(string.byte(String, i))
        then
            rightlim = i
            break
        end
    end

    if leftlim == nil or rightlim == nil
    then
        return { "", 0, 0 }
    else
        leftcut = leftlim - 1
        rightcut = slen - rightlim
        return { string.sub(String, leftlim, rightlim), leftcut, rightcut }
    end
end

local function string_trim(String)
    return string_trim_stats(String)[1]
end

function string_split_trimmed(String, Separator)
    local parts = {}
    local left = nil
    for i=1,#String do
        if String:byte(i) == Separator:byte(1) then
            if not (left == nil) then 
                table.insert(parts, string_trim(String:sub(left+1, i-1)))
            end
            left = i
        end
    end

    return parts
end

local function find_limit(lines, starti, endi, dir)
    for rowi=starti,endi,dir
    do
        if not string_starts(string_trim(lines[rowi]), SEP_STRING)
        then
            return rowi - dir
        end
    end
    return endi
end

local function cells_for_line(line)
    return string_split_trimmed(line, SEP_STRING)
end

local function get_trimed_lines(lines, start_line, end_line)
    local leftcut_min = 0xffffffff -- assume 32 bit
    local lines = table.move(lines, start_line, end_line, 1, {})
    for i, line in ipairs(lines)
    do
        lines[i], leftcut, rightcut = unpack(string_trim_stats(line))
        leftcut_min = math.min(leftcut_min, leftcut)
    end
    return { lines, leftcut_min }
end

local function has_utf8(lines)
    local matrix = {}
    for row,line in ipairs(lines)
    do
        for i=1,#line
        do
            if line:byte(i) >= 128
            then
                return true
            end
        end
    end
    return false
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

local function print_matrix(matrix, left_padding, contains_utf8)
    max_column_len = {}
    local biggest_column = 0
    for row, cells in ipairs(matrix)
    do
        if not line_is_horizontal_separator(cells)
        then
            for col, cell in ipairs(cells)
            do
                if max_column_len[col] == nil
                then
                    max_column_len[col] = contains_utf8 and string_utf8_len(cell) or #cell
                else
                    max_column_len[col] = math.max(max_column_len[col], contains_utf8 and string_utf8_len(cell) or #cell)
                end
            end
        end
    end

    for col, max_len in ipairs(max_column_len)
    do
        biggest_column = math.max(biggest_column, max_len)
    end
    
    local spaces = {}
    for i=1,biggest_column+1
    do
        spaces[i] = string.rep(" ", i)
    end

    new_lines = {}
    for row, cells in ipairs(matrix)
    do
        tab = {}
        tab[#tab + 1] = string.rep(" ", left_padding)
        tab[#tab + 1] = SEP_STRING

        if line_is_horizontal_separator(cells)
        then
            for col, max_len in ipairs(max_column_len)
            do
                separator = string.rep("-", max_column_len[col] + 2)
                fmt = (col == #max_column_len) and "%s" .. SEP_STRING or "%s+"
                tab[#tab + 1] = string.format(fmt, separator)
            end
        else
            for col, max_len in ipairs(max_column_len)
            do
                cell = cells[col] 
                v = (cell == nil) and "" or cell
                space_num = (cell == nil) and max_column_len[col] or max_column_len[col] - (contains_utf8 and string_utf8_len(cell) or #cell)

                tab[#tab + 1] = spaces[space_num+1]
                tab[#tab + 1] = v
                tab[#tab + 1] = " "
                tab[#tab + 1] = SEP_STRING
            end
        end

        new_lines[row] = table.concat(tab)
    end
    return new_lines
end

function M.tablize_under_cursor(lines, cursor_pos)
    local line_count = #lines
    local row, col = unpack(cursor_pos)

    if not string_starts(string_trim(lines[row]), SEP_STRING)
    then
        return nil
    end

    local start_line = find_limit(lines, row, 1, -1)
    local end_line = find_limit(lines, row, line_count, 1)

    local table_lines, left_padding = unpack(get_trimed_lines(lines, start_line, end_line))
    local contains_utf8 = has_utf8(table_lines)
    local matrix = fill_matrix(table_lines)
    local new_lines = print_matrix(matrix, left_padding, contains_utf8)

    return { new_lines, start_line, end_line }
end

function M.tableize()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local line_count = vim.api.nvim_buf_line_count(0)
    local lines = vim.api.nvim_buf_get_lines(0, 0, line_count, false)
    local result = M.tablize_under_cursor(lines, cursor_pos)

    if result then
        local new_lines, start_line, end_line = unpack(result)
        vim.api.nvim_buf_set_lines(0, start_line-1, end_line, false, new_lines)
    end
end

return M
