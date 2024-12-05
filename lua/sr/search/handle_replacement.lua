local config = require("sr.config")

-- Function to perform the actual replacement
local function perform_replacement(files, search_pattern, replacement)
    local count = 0
    for _, file in ipairs(files) do
        local lines = {}
        local file_changed = false

        -- Read file content
        for line in io.lines(file) do
            local new_line, replacements
            if config.options.use_regex then
                new_line, replacements = line:gsub(search_pattern, replacement)
            else
                new_line, replacements = line:gsub(vim.pesc(search_pattern), replacement)
            end

            if replacements > 0 then
                file_changed = true
                count = count + replacements
            end
            table.insert(lines, new_line)
        end

        -- Write changes if file was modified
        if file_changed then
            local f = io.open(file, "w")
            if f then
                f:write(table.concat(lines, "\n"))
                f:close()
            end
        end
    end
    return count
end

-- Handle the replacement process
return function(selections, search_pattern, replacement)
    local count = perform_replacement(selections, search_pattern, replacement)
    vim.notify(string.format("Replaced %d occurrence(s) in %d file(s)", count, #selections))
end
