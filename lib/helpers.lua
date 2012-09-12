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

function email(email)
    return email:find('@') and email or email .. '@anon.org'
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
    
    str = str:gsub('&', '&amp;')
    str = str:gsub('"', '&quot;')
    str = str:gsub("'", '&apos;')
    str = str:gsub('<', '&lt;')
    str = str:gsub('>', '&gt;')
    
    return str
end

function sha1_hex_to_uuid_ish(str)
    assert(str:len() == 40)

    return string.format('%s-%s-%x%s-%x%s-%s',
        str:sub(1,8),
        str:sub(9,12),
        5, str:sub(14,16),
        bit.bor(bit.band(tonumber(str:sub(17, 17), 16), 0x3), 0x8), str:sub(18, 20),
        str:sub(21, 32)
    )
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to
    while true do
        delim_from, delim_to = self:find(delimiter, from)
        if not delim_from then break end
        table.insert(result, self:sub(from, delim_from - 1))
        from = delim_to + 1
    end

    table.insert(result, self:sub(from))
    
    return result
end