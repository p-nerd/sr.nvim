-- Main entry point
return function()
    vim.ui.input({ prompt = "Search pattern: " }, function(search_pattern)
        if not search_pattern then
            return
        end
        require("sr.search.handle_replacement_input")(search_pattern)
    end)
end
