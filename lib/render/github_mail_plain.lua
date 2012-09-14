module(..., package.seeall)
local helpers = require 'lib.helpers'

local escape      = helpers.xml_escape
local noext       = helpers.strip_extension
local fmt_title   = helpers.title
local fmt_message = helpers.message
local fmt_ts      = helpers.timestamp
local fmt_email   = helpers.email
local fmt_uuid    = helpers.sha1_hex_to_uuid_ish


local git2 = require 'lib.git2'

local _config
local _output

function init(config, output)
    _config = config
    _output = output
    
    return _M
end

function header()
    _output(
'New activity for ', _config.title, ' (', _config.subtitle, ')',
"\n\n", '======', "\n"
)
end

function entry(repo, ref, oid, commit)
    local info = git2.commit_info(commit)
    local hash = git2.oid_hash(oid)
    
    local author, title, message;
    if info.committer ~= info.author then
        author = info.author .. "via (" .. info.committer .. ")"
    else
        author = info.author
    end
    
    if info.message and info.message:len() > 0 then
        message = fmt_message(info.message)
        
        if title == message then
            message = ''
        end
    else
        message = 'Unknown'
    end
    
    _output(message, "\n\n")
    _output(author, '@', fmt_ts(info.time), "\n")
    _output("Files modified:\n")
    
    for _, file_info in ipairs(git2.commit_filelist(repo, commit)) do
        _output("\t", '* ', file_info.path, "\n")
    end
    
    _output("\n", 'Commit diff:', "\n", _config.entry.link, 'commit/', hash, "\n")
    _output('======'," \n");
end


function footer()
    _output('-- ', "\n")
    _output('This commit summary was generated @', fmt_ts(), ' by ', LGF_ID, ' version ', LGF_VERSION, ' (', LGF_URL, ').')
end
