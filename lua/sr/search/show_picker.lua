local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local config = require("sr.config")

-- Build the base ripgrep command with common options
local function build_base_command()
    return {
        "rg",
        "--files-with-matches",
        "--no-heading",
        "--hidden", -- Include hidden/dot files
        "--no-ignore-vcs", -- Don't use .gitignore by default
    }
end

-- Add optional flags based on configuration and environment
local function add_optional_flags(command)
    -- Check for .gitignore and respect it if present
    if vim.fn.filereadable(".gitignore") == 1 then
        table.insert(command, "--respect-gitignore")
    end

    -- Add case sensitivity option
    if config.options.ignore_case then
        table.insert(command, "--ignore-case")
    end
end

-- Configure picker mappings
local function configure_mappings(prompt_bufnr, map, search_pattern, replacement)
    -- Replace in selected files
    actions.select_default:replace(function()
        require("sr.search.process_selections")(prompt_bufnr, search_pattern, replacement)
    end)

    -- Enable multi-selection
    map("i", "<Tab>", actions.toggle_selection)
    map("n", "<Tab>", actions.toggle_selection)
    return true
end

-- Create picker configuration
local function create_picker_config(search_pattern, replacement)
    local rg_command = build_base_command()
    add_optional_flags(rg_command)
    table.insert(rg_command, search_pattern)

    return {
        prompt_title = "Search Results",
        ---@diagnostic disable-next-line: undefined-field
        finder = finders.new_oneshot_job(rg_command, { cwd = vim.loop.cwd() }),
        sorter = conf.generic_sorter({}),
        previewer = conf.file_previewer({}),
        attach_mappings = function(prompt_bufnr, map)
            return configure_mappings(prompt_bufnr, map, search_pattern, replacement)
        end,
    }
end

-- Main function to create and show the picker
return function(search_pattern, replacement)
    local picker = pickers.new({}, create_picker_config(search_pattern, replacement))
    picker:find()
end
