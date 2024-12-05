local function handle_replacement_input(search_pattern)
    vim.ui.input({ prompt = "Replace with: " }, function(replacement)
        if not replacement then
            return
        end
        require("sr.search.show_picker")(search_pattern, replacement)
    end)
end

return function()
    vim.ui.input({ prompt = "Search pattern: " }, function(search_pattern)
        if not search_pattern then
            return
        end
        handle_replacement_input(search_pattern)
    end)
end
