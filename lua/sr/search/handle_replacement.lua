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
            local bufnr = vim.fn.bufnr(file)

            -- If buffer exists and is loaded
            if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
                -- Save current modification state
                local modified = vim.api.nvim_buf_get_option(bufnr, "modified")

                -- Temporarily set nomodified to avoid the warning
                vim.api.nvim_buf_set_option(bufnr, "modified", false)

                -- Update buffer content
                local content = table.concat(lines, "\n")
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(content, "\n"))

                -- Restore original modification state
                vim.api.nvim_buf_set_option(bufnr, "modified", modified)
            end

            -- Write to file
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
