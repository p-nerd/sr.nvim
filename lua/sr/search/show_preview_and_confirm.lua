local config = require("sr.config")

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

-- Show preview window and handle confirmation
return function(selections, search_pattern, replacement)
    local preview_buf = vim.api.nvim_create_buf(false, true)
    -- Set up the preview window
    local preview_win = vim.api.nvim_open_win(preview_buf, true, {
        relative = "editor",
        width = math.floor(vim.o.columns * 0.8),
        height = math.floor(vim.o.lines * 0.8),
        row = math.floor(vim.o.lines * 0.1),
        col = math.floor(vim.o.columns * 0.1),
        style = "minimal",
        border = "rounded",
    })

    -- Generate preview content
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

    -- Set preview content
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, preview_content)

    -- Create a global function for handling the confirmation
    local func_name = "_SearchReplaceConfirm_" .. preview_buf
    _G[func_name] = function(confirmed)
        vim.api.nvim_win_close(preview_win, true)
        if confirmed then
            require("sr.search.handle_replacement")(selections, search_pattern, replacement)
        end
        -- Clean up the global function
        _G[func_name] = nil
    end

    -- Add keymaps
    vim.api.nvim_buf_set_keymap(
        preview_buf,
        "n",
        "y",
        string.format([[<cmd>lua _G['%s'](true)<CR>]], func_name),
        { noremap = true, silent = true }
    )

    vim.api.nvim_buf_set_keymap(
        preview_buf,
        "n",
        "n",
        string.format([[<cmd>lua _G['%s'](false)<CR>]], func_name),
        { noremap = true, silent = true }
    )

    -- Add help text and make buffer non-modifiable
    local help_text = { "", "Press 'y' to apply changes, 'n' to cancel" }
    local current_lines = vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false)
    vim.list_extend(current_lines, help_text)
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, current_lines)
    vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)
end
