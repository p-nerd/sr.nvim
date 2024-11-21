local M = {}

M.options = {
    keymap = "<leader>sr",
    ignore_case = false,
    use_regex = false,
    preview_changes = true,
    live_preview = true,
}

function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
