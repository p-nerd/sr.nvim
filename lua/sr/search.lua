local M = {}

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
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

-- Preview changes function
local function preview_changes(bufnr, search_pattern, replacement)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local preview_lines = {}

    for i, line in ipairs(lines) do
        local new_line = line:gsub(config.options.use_regex and search_pattern or vim.pesc(search_pattern), replacement)
        if new_line ~= line then
            table.insert(preview_lines, string.format("Line %d:", i))
            table.insert(preview_lines, "- " .. line)
            table.insert(preview_lines, "+ " .. new_line)
            table.insert(preview_lines, "")
        end
    end

    return preview_lines
end

function M.search_and_replace()
    -- Get the search pattern from user
    vim.ui.input({ prompt = "Search pattern: " }, function(search_pattern)
        if not search_pattern then
            return
        end

        -- Get the replacement text
        vim.ui.input({ prompt = "Replace with: " }, function(replacement)
            if not replacement then
                return
            end

            -- Build rg command with options
            local rg_command = { "rg", "--files-with-matches", "--no-heading" }
            if config.options.ignore_case then
                table.insert(rg_command, "--ignore-case")
            end
            table.insert(rg_command, search_pattern)

            -- Create a picker to show search results
            local picker = pickers.new({}, {
                prompt_title = "Search Results",
                finder = finders.new_oneshot_job(rg_command, { cwd = vim.loop.cwd() }),
                sorter = conf.generic_sorter({}),
                previewer = conf.file_previewer({}),
                attach_mappings = function(prompt_bufnr, map)
                    -- Replace in selected files
                    actions.select_default:replace(function()
                        local selections = {}
                        local current_picker = action_state.get_current_picker(prompt_bufnr)

                        -- Get all selected entries
                        for _, entry in ipairs(current_picker:get_multi_selection()) do
                            table.insert(selections, entry.value)
                        end

                        -- If nothing is selected, get the entry under cursor
                        if #selections == 0 then
                            local selection = action_state.get_selected_entry()
                            if selection then
                                table.insert(selections, selection.value)
                            end
                        end

                        -- Close the picker
                        actions.close(prompt_bufnr)

                        -- Preview changes if enabled
                        if config.options.preview_changes then
                            local preview_buf = vim.api.nvim_create_buf(false, true)
                            local preview_win = vim.api.nvim_open_win(preview_buf, true, {
                                relative = "editor",
                                width = math.floor(vim.o.columns * 0.8),
                                height = math.floor(vim.o.lines * 0.8),
                                row = math.floor(vim.o.lines * 0.1),
                                col = math.floor(vim.o.columns * 0.1),
                                style = "minimal",
                                border = "rounded",
                            })

                            local preview_content = { "Preview of changes:", "" }
                            for _, file in ipairs(selections) do
                                local file_buf = vim.fn.bufadd(file)
                                vim.fn.bufload(file_buf)
                                local changes = preview_changes(file_buf, search_pattern, replacement)
                                if #changes > 0 then
                                    table.insert(preview_content, "File: " .. file)
                                    vim.list_extend(preview_content, changes)
                                end
                            end

                            vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, preview_content)
                            vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)

                            -- Ask for confirmation
                            vim.ui.select({ "Yes", "No" }, {
                                prompt = "Apply these changes?",
                            }, function(choice)
                                vim.api.nvim_win_close(preview_win, true)
                                if choice == "Yes" then
                                    local count = perform_replacement(selections, search_pattern, replacement)
                                    vim.notify(
                                        string.format("Replaced %d occurrence(s) in %d file(s)", count, #selections)
                                    )
                                end
                            end)
                        else
                            -- Perform the replacement directly
                            local count = perform_replacement(selections, search_pattern, replacement)
                            vim.notify(string.format("Replaced %d occurrence(s) in %d file(s)", count, #selections))
                        end
                    end)

                    -- Enable multi-selection
                    map("i", "<Tab>", actions.toggle_selection)
                    map("n", "<Tab>", actions.toggle_selection)

                    return true
                end,
            })

            picker:find()
        end)
    end)
end

return M
