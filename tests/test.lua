local Mod = require("tableize")

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function test_compare_lines(expected, received)
    for line_index, line_exp in ipairs(expected)
    do
        line_received = received[line_index]
        if not (line_exp == line_received)
        then
            print(string.format("Failed! [%s] != [%s]", line_exp, line_received))
        end
    end
end

function test_general()
    local input = {
        "| Testing | COl 2 | a |         ",
        "    | --- | | |   ",
        "          | asdf | COasdfjkll 2 | |",
        "| iouret28 | C238838888Ol 2 | |",
        "| l;asdjg;jb | COl 2hahahah | |",
        "| laksdflasdlklk | ",
    }

    local expected = {
        "|        Testing |          COl 2 | a |",
        "|----------------|----------------|---|",
        "|           asdf |   COasdfjkll 2 |   |",
        "|       iouret28 | C238838888Ol 2 |   |",
        "|     l;asdjg;jb |   COl 2hahahah |   |",
        "| laksdflasdlklk |                |   |",
    }

    local result = Mod.tablize_under_cursor(input, { 1, 1 })
    local new_lines, start_line, end_line = unpack(result)
    test_compare_lines(expected, new_lines)
end

function test_general_with_pluses()
    local input = {
        "| Testing | COl 2 | a |         ",
        "    | +++ | | |   ",
        "          | asdf | COasdfjkll 2 | |",
        "| iouret28 | C238838888Ol 2 | |",
        "| l;asdjg;jb | COl 2hahahah | |",
        "| laksdflasdlklk | ",
    }

    local expected = {
        "|        Testing |          COl 2 | a |",
        "|            +++ |                |   |",
        "|           asdf |   COasdfjkll 2 |   |",
        "|       iouret28 | C238838888Ol 2 |   |",
        "|     l;asdjg;jb |   COl 2hahahah |   |",
        "| laksdflasdlklk |                |   |",
    }

    local result = Mod.tablize_under_cursor(input, { 1, 1 })
    local new_lines, start_line, end_line = unpack(result)
    test_compare_lines(expected, new_lines)
end

function test_general_with_indent_before()
    local input = {
        "  | Testing | COl 2 | a |         ",
        "    | --- | | |   ",
        "          | asdf | COasdfjkll 2 | |",
        "  | iouret28 | C238838888Ol 2 | |",
        "  | l;asdjg;jb | COl 2hahahah | |",
        "  | laksdflasdlklk | ",
    }

    local expected = {
        "  |        Testing |          COl 2 | a |",
        "  |----------------|----------------|---|",
        "  |           asdf |   COasdfjkll 2 |   |",
        "  |       iouret28 | C238838888Ol 2 |   |",
        "  |     l;asdjg;jb |   COl 2hahahah |   |",
        "  | laksdflasdlklk |                |   |",
    }

    local result = Mod.tablize_under_cursor(input, { 1, 1 })
    local new_lines, start_line, end_line = unpack(result)
    test_compare_lines(expected, new_lines)
end

function test_general_with_indent_before_min()
    local input = {
        "  | Testing | COl 2 | a |         ",
        "    | --- | | |   ",
        "          | asdf | COasdfjkll 2 | |",
        "  | iouret28 | C238838888Ol 2 | |",
        "  | l;asdjg;jb | COl 2hahahah | |",
        " | laksdflasdlklk | ",
    }

    local expected = {
        " |        Testing |          COl 2 | a |",
        " |----------------|----------------|---|",
        " |           asdf |   COasdfjkll 2 |   |",
        " |       iouret28 | C238838888Ol 2 |   |",
        " |     l;asdjg;jb |   COl 2hahahah |   |",
        " | laksdflasdlklk |                |   |",
    }

    local result = Mod.tablize_under_cursor(input, { 1, 1 })
    local new_lines, start_line, end_line = unpack(result)
    test_compare_lines(expected, new_lines)
end

function test_general_with_indent_before_no_padding_one()
    local input = {
        "| Testing | COl 2 | a |         ",
        "    | --- | | |   ",
        "          | asdf | COasdfjkll 2 | |",
        "  | iouret28 | C238838888Ol 2 | |",
        "  | l;asdjg;jb | COl 2hahahah | |",
        " | laksdflasdlklk | ",
    }

    local expected = {
        "|        Testing |          COl 2 | a |",
        "|----------------|----------------|---|",
        "|           asdf |   COasdfjkll 2 |   |",
        "|       iouret28 | C238838888Ol 2 |   |",
        "|     l;asdjg;jb |   COl 2hahahah |   |",
        "| laksdflasdlklk |                |   |",
    }

    local result = Mod.tablize_under_cursor(input, { 1, 1 })
    local new_lines, start_line, end_line = unpack(result)
    test_compare_lines(expected, new_lines)
end

function test_polish_letters()
    local input = {
        "|   Dzień | Zarobek [zł] |   Kto był na zmianie |",
        "|----------|---------------|-----------------------|",
        "|   Środa |           100 | Ania, Krzysiek, Tomek |",
        "| Czwartek |           100 |          Sylwia, Ania |",
        "|  Piątek |           400 |                       |",
    }

    local expected = {
        "|    Dzień | Zarobek [zł] |    Kto był na zmianie |",
        "|----------|--------------|-----------------------|",
        "|    Środa |          100 | Ania, Krzysiek, Tomek |",
        "| Czwartek |          100 |          Sylwia, Ania |",
        "|   Piątek |          400 |                       |",
    }

    local result = Mod.tablize_under_cursor(input, { 1, 1 })
    local new_lines, start_line, end_line = unpack(result)
    test_compare_lines(expected, new_lines)
end

function test_aligning()
    local input = {
        "| Testing | COl 2 | a |         ",
        "    | :-: | :-| -:|   ",
        "          | asdf | COasdfjkll 2 | |",
        "| iouret28 | C238838888Ol 2 | |",
        "| iourt28 | C238838888Ol 2 | |",
        "| l;asdjg;jb | COl 2hahahah | |",
        "| laksdflasdlklk | ",
        "    | :- | :-:| -|   ",
        "          | asdf | COasdfjkll 2 | |",
        "| iouret28 | C238838888Ol 2 | |",
        "| iourt28 | C238838888Ol 2 | |",
        "| l;asdjg;jb | COl 2hahahah | |",
        "| laksdflasdlklk | ",
    }

    local expected = {
        "|        Testing |          COl 2 | a |",
        "|:--------------:|:---------------|--:|",
        "|      asdf      | COasdfjkll 2   |   |",
        "|    iouret28    | C238838888Ol 2 |   |",
        "|     iourt28    | C238838888Ol 2 |   |",
        "|   l;asdjg;jb   | COl 2hahahah   |   |",
        "| laksdflasdlklk |                |   |",
        "|:---------------|:--------------:|---|",
        "| asdf           |  COasdfjkll 2  |   |",
        "| iouret28       | C238838888Ol 2 |   |",
        "| iourt28        | C238838888Ol 2 |   |",
        "| l;asdjg;jb     |  COl 2hahahah  |   |",
        "| laksdflasdlklk |                |   |",
    }

    local result = Mod.tablize_under_cursor(input, { 1, 1 })
    local new_lines, start_line, end_line = unpack(result)
    test_compare_lines(expected, new_lines)
end

function test_dividiers()
    local input = {
        "| Testing | COl 2 | a |         ",
        "    | -",
        "          | asdf | COasdfjkll 2 | |",
        "| iouret28 | C238838888Ol 2 | |",
        "| iourt28 | C238838888Ol 2 | |",
        "| l;asdjg;jb | COl 2hahahah | |",
        "| laksdflasdlklk | ",
        "    |  |   ",
        "          | asdf | COasdfjkll 2 | |",
        "| iouret28 | C238838888Ol 2 | |",
        "| iourt28 | C238838888Ol 2 | |",
        "| l;asdjg;jb | COl 2hahahah | |",
        "| laksdflasdlklk | ",
    }

    local expected = {
        "|        Testing |          COl 2 | a |",
        "|----------------|----------------|---|",
        "|           asdf |   COasdfjkll 2 |   |",
        "|       iouret28 | C238838888Ol 2 |   |",
        "|        iourt28 | C238838888Ol 2 |   |",
        "|     l;asdjg;jb |   COl 2hahahah |   |",
        "| laksdflasdlklk |                |   |",
        "|----------------|----------------|---|",
        "|           asdf |   COasdfjkll 2 |   |",
        "|       iouret28 | C238838888Ol 2 |   |",
        "|        iourt28 | C238838888Ol 2 |   |",
        "|     l;asdjg;jb |   COl 2hahahah |   |",
        "| laksdflasdlklk |                |   |",
    }

    local result = Mod.tablize_under_cursor(input, { 1, 1 })
    local new_lines, start_line, end_line = unpack(result)
    test_compare_lines(expected, new_lines)
end

test_general()
test_general_with_pluses()
test_general_with_indent_before()
test_general_with_indent_before_min()
test_general_with_indent_before_no_padding_one()
test_polish_letters()
test_aligning()
test_dividiers()
