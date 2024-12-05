return function(search_pattern)
    vim.ui.input({ prompt = "Replace with: " }, function(replacement)
        if not replacement then
            return
        end
        require("sr.search.show_picker")(search_pattern, replacement)
    end)
end
