local M = {}

--- @param user opt
M.setup = function (user)
    --- @type opt
    local defaults = require('nbted-nvim.defaults').defaults
    --- @type opt
    local opts = vim.tbl_deep_extend('keep', user, defaults)
    require('nbted-nvim.main').main(opts, M)
    M.setup = nil
end

return M
