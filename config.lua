-- Example config for lgfeed
module('config')

-- Feed configuration
render    = 'gollum'
output    = 'stdout'

title     = 'untitled'
link      = 'http://www.example.org'
author    = 'unknown'
subtitle  = 'untitled but smaller'
id        = 'http://www.example.org/lgfeed/feed.xml'
self      = id

entry = {}
entry.link = 'http://www.example.org'
entry.id   = entry.link

return _M