
local stdout = _G.io.stdout
local ipairs = _G.ipairs
local unpack = _G.unpack
module(...)

function init()
    return function(...)
        local args = {...}
        for i = 1, #args do
            if not args[i] then
                stdout:write('')
            else
                stdout:write(args[i])
            end
        end
    end
end