local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local config = require("sr.config")

-- Create and show the picker
return function(search_pattern, replacement)
    -- Build rg command with options
    local rg_command = {
        "rg",
        "--files-with-matches",
        "--no-heading",
        "--hidden", -- Include hidden files
        "--no-ignore", -- Don't respect ignore files (.gitignore, etc)
        "--glob", -- But explicitly respect .git
        "!.git/*", -- Exclude .git directory
    }

    if config.options.ignore_case then
        table.insert(rg_command, "--ignore-case")
    end

    table.insert(rg_command, search_pattern)

    -- Create a picker to show search results
    local picker = pickers.new({}, {
        prompt_title = "Search Results",
        ---@diagnostic disable-next-line: undefined-field
        finder = finders.new_oneshot_job(rg_command, { cwd = vim.loop.cwd() }),
        sorter = conf.generic_sorter({}),
        previewer = conf.file_previewer({}),
        attach_mappings = function(prompt_bufnr, map)
            -- Replace in selected files
            actions.select_default:replace(function()
                require("sr.search.process_selections")(prompt_bufnr, search_pattern, replacement)
            end)
            -- Enable multi-selection
            map("i", "<Tab>", actions.toggle_selection)
            map("n", "<Tab>", actions.toggle_selection)
            return true
        end,
    })
    picker:find()
end
