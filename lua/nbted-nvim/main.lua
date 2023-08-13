--- Main functionalities.

--- @param opts opt
--- @param M table
local main = function (opts, M)
    local l = require 'nbted-nvim.lib'
    M.decode = function ()
        local dest, tempbuf = l.decode(opts)
        M.encode = function () l.encode(opts, dest) end
        if opts.auto_encode then l.setup_auto_encode_au(opts, M, tempbuf) end
    end

    if opts.auto_detect_nbt then l.setup_auto_detect_au(opts, M) end
    if opts.enable_commands then l.setup_commands(opts, M) end
end

return { main = main }
