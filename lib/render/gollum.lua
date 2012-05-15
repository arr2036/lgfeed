module(..., package.seeall)
local helpers = require 'lib.helpers'

local escape  = helpers.xml_escape
local title   = helpers.title
local message = helpers.message
local ts      = helpers.timestamp
local noext   = helpers.strip_extension

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
    <updated>]] , ts(), [[</updated>
    <id>]]      , _config.id, [[</id>
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
    
    for _, file in ipairs(git2.commit_filelist(repo, commit)) do
        _output(
[[
    <entry>
        <title>]], escape(title(info.message)), [[</title>
        <link href="]], _config.entry.link, '/', escape(noext(file)), '/', hash, [["/>
        <id>urn:uuid:]], hash, [[</id> 
        <author>
            <name>]]  , escape(info.author), [[</name>
            <email>]] , escape(info.author_email),  [[</email>
        </author>
        <updated>]]   , ts(info.time), [[</updated>
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
        
        if hash_p then
        _output(
[[
        <summary type='html'>
            <p>]], escape(message(info.message)) , [[</p>
            <p><a href="]],_config.entry.link, '/compare/', escape(noext(file)), '/', hash_p, '...', hash, [[">[diff]</a></p>
        </summary>
]]
                )
        else
        _output(
[[
        <summary type='html'>
            <p>]], escape(message(info.message)) , [[</p>
            <p>initial commit</p>
        </summary>
]]
                )        
        end
        
        _output [[
    </entry>
]]
    end
end


function footer()
    _output [[</feed>]]
end