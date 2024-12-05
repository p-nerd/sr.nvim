local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local config = require("sr.config")

-- Process selected files
return function(prompt_bufnr, search_pattern, replacement)
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

    -- Handle preview or direct replacement
    if config.options.preview_changes then
        require("sr.search.show_preview_and_confirm")(selections, search_pattern, replacement)
    else
        require("sr.search.handle_replacement")(selections, search_pattern, replacement)
    end
end
