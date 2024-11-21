local M = {}

function M.setup(opts)
    local config = require("sr.config")
    config.setup(opts)

    -- Set up the command and keymap
    vim.api.nvim_create_user_command("SearchReplace", function()
        require("sr.search").search_and_replace()
    end, {})

    -- Set up keymap if provided
    if config.options.keymap then
        vim.keymap.set("n", config.options.keymap, function()
            require("sr.search").search_and_replace()
        end, { desc = "Search and replace across files", silent = true })
    end
end

return M
