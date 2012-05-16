module(..., package.seeall)
local helpers = require 'lib.helpers'

local escape      = helpers.xml_escape
local noext       = helpers.strip_extension
local fmt_title   = helpers.title
local fmt_message = helpers.message
local fmt_ts      = helpers.timestamp


local git2    = require 'lib.git2'

local _config
local _output

function init(config, output)
    _config = config
    _output = output
    
    return _M
end

function header()
    _output([[
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom"> 
    <title>]]   , _config.title      , [[</title>
    <logo>]]    , _config.logo       , [[</logo>
    <subtitle>]], _config.subtitle   , [[</subtitle>
    <updated>]] , fmt_ts()           , [[</updated>
    <id>]]      , _config.id         , [[</id>
    <author>
        <name>]], _config.author, [[</name>
    </author>
    <generator uri="]], LGF_URL ,[[" version="]], LGF_VERSION, [[">]], LGF_ID , [[</generator>
]])
end

function entry(repo, ref, oid, commit)
    local info = git2.commit_info(commit)
    local hash = git2.oid_hash(oid)
    local hash_p
    
    -- Commits in gollum usually only have one parent
    if git2.commit_parentcount(commit) > 0 then 
        hash_p = git2.oid_hash(git2.commit_parent_oid(commit, 0))
    end
    
    local message; local title;
    
    if info.message and info.message:len() > 0 then
        title   = escape(fmt_title(info.message))
        message = escape(fmt_message(info.message))
    else
        title   = 'changes not described.'
        message = 'Changes were not described.'
    end
    
    for _, file in ipairs(git2.commit_filelist(repo, commit)) do
        file = escape(noext(file))
        
        _output(
[[
    <entry>
        <title>]], file, ' updated -- ', title, [[</title>
        <link href="]], _config.entry.link, '/', file, [["/>
        <id>urn:uuid:]], hash, [[</id> 
        <author>
            <name>]]  , escape(info.author), [[</name>
            <email>]] , escape(info.author_email),  [[</email>
        </author>
        <updated>]]   , fmt_ts(info.time), [[</updated>
]]
            )
    
        if info.author ~= info.committer then
            _output(
[[
        <contributor>
            <name>]], escape(info.committer) ,[[</name>
            <email>]], escape(info.committer_email), [[</email>
        </contributor>
]]
                    )
        end
        
        _output(
[[
        <summary type='html'>
            <p>]],
                '<a href="mailto:', escape(info.author_email), '">', escape(info.author),'</a>',
                ' modified ',
                '<a href="', _config.entry.link, '/', file, '">', file, '</a> ',
                '[<a href="', _config.entry.link, '/', file, '/', hash, '">', hash:sub(1, 7), [[</a>]</p>
            <p>]], message ,[[</p>
]])
        if hash_p then
            _output(
[[
            <p><a href="]], _config.entry.link, '/compare/', file, '/', hash_p, '...', hash, [[">Show changes...</a></p>
]])
        end
 
        _output(
[[
        </summary>
]])
        
        _output([[
    </entry>
]])
    end
end


function footer()
    _output [[</feed>]]
end