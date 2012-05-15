--[[Module: lib.lib
Wrappers for liblib.
--]]

local require  = _G.require
local tonumber = _G.tonumber
local print    = _G.print

local log_debug = _G.loglog_debug
local log_warn  = _G.loglog_warn
local log_error = _G.log_error

module(..., package.seeall)


function timestamp(unix)
    unix = unix or os.time()
    
    return os.date('%Y-%m-%dT%H:%M:%SZ', unix)
end

function title(message)
    local eol = message:find('[\r\n]')
    
    if not eol then
        return message
    end
    
    return message:sub(1, eol - 1)
end

function message(message)
    local eol = message:find('[\r\n]$')
    
    if not eol then
        return message
    end
    
    return message:sub(1, eol - 1)
end

function strip_extension(path)
    local ext = path:find('[.][^.]+$')
    
    if not ext then
        return path
    end
    
    return path:sub(1, ext - 1)
end

function xml_escape(str)
    if not str then return '' end
    
    str = str:gsub('"', '&quot;')
    str = str:gsub("'", '&apos;')
    str = str:gsub('<', '&lt;')
    str = str:gsub('>', '&gt;')
    str = str:gsub('&', '&amp;')
    
    return str
end