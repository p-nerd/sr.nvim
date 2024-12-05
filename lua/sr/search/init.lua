local M = {}

-- Main entry point
function M.search_and_replace()
    vim.ui.input({ prompt = "Search pattern: " }, function(search_pattern)
        if not search_pattern then
            return
        end
        require("sr.search.handle_replacement_input")(search_pattern)
    end)
end

return M
