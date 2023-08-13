-- Default setup, to be overidden by user setup.

local M = {}

--- @type opt
M.defaults = { auto_detect_nbt = false
             , auto_encode = false
             , enable_commands = false
             , backup_on_encode = true
             , verbose = true
             , nbted_command = 'nbted'
             , detect_nbt = 'auto'
             , minecraft_dir = 'infer'
             }

return M
