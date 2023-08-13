local M = {}

--- @param opts opt
local log = function (opts)
    --- @param msg string
    return function (msg)
        if opts.verbose then
            print('[nbted-nvim] ' .. msg)
        end
    end
end

--- @param msg string
--- @return any
local err = function (msg)
    error('[nbted-nvim] ' .. msg)
end

--- Infer Minecraft data directory by OS.
--- https://help.minecraft.net/hc/en-us/articles/4409159214605-Managing-Data-and-Game-Storage-in-Minecraft-Java-Edition-#h_01FGA90Z06DE00GT8E81SWX9SE
--- @param os_ string
--- @return filepath
local infer_minecraft_dir_by_os = function (os_)
    if os_ == 'Linux' then return os.getenv('HOME') .. '/.minecraft/'
    elseif os_ == 'OSX' then return os.getenv('HOME') .. '/Library/Application Support/minecraft/'
    elseif os_ == 'Windows' then return os.getenv('APPDATA') .. '/.minecraft/'
    else return err(string.format('your operating system %s does not match Linux, OSX or Windows, therefore I cannot infer your minecraft directory.', os_))
    end
end

--- Infer Minecraft data directory, using `jit.os` to find out current OS.
--- @see infer_minecraft_dir_by_os
--- @return filepath
local infer_minecraft_dir = function (opts)
    local inferred = infer_minecraft_dir_by_os(jit.os)
    if opts.verbose then
        log(opts)(string.format('inferred Minecraft data directory: %s', inferred))
    end
    return inferred
end

--- Get Minecraft data directory, either provided by user or inferred.
--- NOTE: May not be escaped and may contain spaces!
--- @param opts opt
--- @return filepath
local get_minecraft_dir = function (opts)
    if opts.minecraft_dir == 'infer' then
        if opts.verbose then log(opts) 'inferring Minecraft data directory with your OS...' end
        return infer_minecraft_dir(opts)
    else
        return opts.minecraft_dir
    end
end

--- Determine if str1 is prefix of str2.
--- Pattern matche allowed.
--- @param str1 string
--- @param str2 string
--- @return boolean
local is_prefix = function (str1, str2)
    local a, _ = string.find(str2, str1)
    return a == 1
end

--- Determine if str1 is suffix of str2.
--- Pattern match allowed.
--- @param str1 string
--- @param str2 string
--- @return boolean
local is_suffix = function (str1, str2)
    local _, e = string.find(str2, str1)
    return e == #str2
end

--- Determine if a file is in Minecraft file directory.
--- @param f filepath
--- @return boolean
local in_minecraft_dir = function (opts, f)
    local minecraft_dir = get_minecraft_dir(opts)
    return is_prefix(minecraft_dir, f)
end

--- https://minecraft.fandom.com/wiki/NBT_format#Uses
--- @type filepath[]
local dats = { 'level.dat'
             , 'servers.dat'
             , 'idcounts.dat'
             , 'villages.dat'
             , 'raids.dat'
             , 'map_%d+.dat'
             , 'hotbar.dat'
             , 'scoreboard.dat'
             }

--- Determine if a file is a standard Minecraft data file.
--- @see dats
--- @param f filepath
--- @return boolean
local is_standard_data_file = function (opts, f)
    for _, dat in pairs(dats) do
        if dat == f or is_suffix('/' .. dat, f) then 
            if opts.verbose then log(opts) ('NBT detected: filename matches the standard NBT file `' .. dat .. '`.') end
            return true 
        end
    end

    return false
end

--- Determine if a file is a data file.
--- @param f filepath
--- @return boolean
local is_data_file = function (f)
    return is_suffix('.dat', f)
end

--- Determine if a file is a data file inside the Minecraft directory.
--- @param opts opt
--- @param f filepath
--- @return boolean
local is_a_dat_file_in_minecraft_dir = function (opts, f)
    local yes = is_data_file(f) and in_minecraft_dir(opts, f)
    if yes and opts.verbose then
        log(opts) 'NBT detected. Reason: .dat file inside Minecraft data directory.'
    end
    return yes
end

--- Determine if a file is a compressed NBT file
--- based on its filename.
--- @param f filepath
--- @param opts opt
--- @return boolean
--- @see is_std_data_file
--- @see in_minecraft_dir
M.detect_nbt = function (opts, f)
    return is_standard_data_file(opts, f) or is_a_dat_file_in_minecraft_dir(opts, f) 
end

--- @return filepath
local curr_file_escaped = function ()
    return vim.fn.expand('%:p:S')
end

--- @return filepath
local curr_file = function ()
    return vim.fn.expand('%:p')
end

--- @return string
local timenow_str = function ()
    local s = os.date('%Y%m%d-%H%M%S') --- @cast s string
    return s
end

--- @param f filepath
--- @return filepath
local appendtime = function (f)
    return f .. '-' .. timenow_str()
end

--- @type integer
local auto_encode_group = vim.api.nvim_create_augroup('auto-encode-group', {})
--- @type integer
local auto_detect_group = vim.api.nvim_create_augroup('auto-detect-group', {})

--- @param opts opt
--- @param f filepath
local backup = function (opts, f, bufnr)
    local orig_name = f
    local orig_file, e = io.open(orig_name, 'r')
    if orig_file == nil then return err(string.format('error in copying file %s: %s', orig_file, e)) end
    orig_file:seek('set')
    local content = orig_file:read('*a')
    orig_file:close()
    local backup_name = appendtime(f)
    local backup_file, err2 = io.open(backup_name, 'w+')
    if backup_file == nil then return err(string.format('error in opening backup file %s: %s', backup_name, err2)) end
    backup_file:write(content)
    backup_file:flush()
    backup_file:close()

    if opts.verbose then log(opts)('backed ' .. orig_name .. ' up to ' .. backup_name) end
    vim.b[bufnr].did_backup = true
end

--- Try to read and encode the current file (or should I read buffer?) 
--- into compressed NBT, put the result into dest, 
--- which will be created if not exists, or overridden if exists.
--- @param opts opt
--- @param dest filepath
local encode = function (opts, dest)
    local nbted = opts.nbted_command
    if opts.backup_on_encode and not vim.b.did_backup then 
        backup(opts, dest, vim.fn.bufnr '%')
    end
    local destfile, e = io.open(dest, 'w+b')
    if destfile == nil then return err('error in opening destfile ' .. dest .. ': ' .. e and e or 'nil') end
    local nbted_process_str = string.format('%s -r %s -o %s', nbted, curr_file_escaped(), dest)
    local h = io.popen(nbted_process_str)
    if h == nil then return err(string.format('error in running nbted process %s', nbted_process_str)) end
    h:flush()
    h:close()
    destfile:flush()
    destfile:close()
    if opts.verbose then log(opts)('encoded current buffer to ' .. dest) end
end

--- Try to read and decode the current file into human-readable text,
--- put the result into a tempfile and display it to the user upon success.
--- Returns the original filename and buffer number of the new tempfile.
--- @param opts opt
--- @return filepath, integer
local decode = function (opts)
    local thisfile = curr_file()
    local thisfile_s = curr_file_escaped()
    local nbted = opts.nbted_command
    local tempname = os.getenv('TMPDIR') .. vim.fn.expand('%:t') .. '.nbted'
    local tempfile, e = io.open(tempname, 'w+')
    if tempfile == nil then return err('error in opening tempfile ' .. tempname .. ': ' .. e and e or 'nil'), -1 end
    local nbted_process_str = string.format('%s -p %s -o %s', nbted, thisfile_s, tempname)
    local h = io.popen(nbted_process_str)
    if h == nil then return err(string.format('error in running nbted process %s', nbted_process_str)), -1 end
    h:flush()
    h:close()
    tempfile:flush()
    tempfile:close()
    vim.cmd.edit(tempname)
    vim.cmd.setfiletype 'nbted'
    local bufnr = vim.fn.bufnr '%'

    if opts.verbose then log(opts)('decoded current buffer to ' .. tempname) end

    return thisfile, bufnr
end

--- Set up commands.
--- @param _ opt
--- @param m table
local setup_commands = function (_, m)
    --- @type table<string, fun()>
    local cmds = { decode = function () m.decode() end
                 , encode = function () m.encode() end
                 }

    --- @param o table
    local nbt = function (o)
        local arg = o.fargs[1]
        local action = cmds[arg]
        if action == nil then return err('unknown command: ' .. arg) end
        action()
    end

    --- @return string[]
    local complete = function (_, _, _)
        return vim.tbl_keys(cmds)
    end

    vim.api.nvim_create_user_command('NBT', nbt, { nargs = 1, complete = complete })
end

--- Set up an autocmd that,
--- when loaded a file that *could* be compressed NBT,
--- immediately begin to edit on the human-readable translation.
--- User may override the method of NBT detection by
--- passing a function to `opts.detect_nbt`.
--- @param opts opt
--- @param m table
local setup_auto_detect_au = function (opts, m)
    local callback = function (args)
        local filename = args.file
        local is_nbt = (function ()
            if opts.detect_nbt == 'auto' then
                return require('nbted-nvim.lib').detect_nbt(opts, filename)
            else
                return opts.detect_nbt(filename)
            end
        end)()

        if is_nbt then
            log(opts) 'detected compressed NBT file, auto decoding...'
            m.decode()
        end 
    end

    vim.api.nvim_create_autocmd('BufEnter', { group = auto_detect_group
                                            , callback = callback
                                            })
end

--- Set up an autocmd that,
--- when on the buffer of translated nbt, 
--- encodes the edits whenever saved.
--- @param _ opt
--- @param m table
--- @param buf integer
local setup_auto_encode_au = function (_, m, buf)
    local callback = function ()
        m.encode()
    end

    vim.api.nvim_create_autocmd('BufWritePost', { group = auto_encode_group
                                                , callback = callback
                                                , buffer = buf
                                                })
end

-- exporting

M.decode = decode
M.encode = encode
M.setup_auto_encode_au = setup_auto_encode_au
M.setup_auto_detect_au = setup_auto_detect_au
M.setup_commands = setup_commands

return M


