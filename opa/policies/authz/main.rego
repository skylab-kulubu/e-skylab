package skylab.authz

import future.keywords.if
import data.skylab.events
import data.skylab.announcements
import data.skylab.cms
import data.skylab.users
import data.skylab.seasons
import data.skylab.competitors
import data.skylab.media
import data.skylab.event_types
import data.skylab.common

default allow = false


allow if {
    common.is_authenticated
    _module_allow
}


_module_allow if events.allow
_module_allow if announcements.allow
_module_allow if cms.allow
_module_allow if users.allow
_module_allow if seasons.allow
_module_allow if competitors.allow
_module_allow if media.allow
_module_allow if event_types.allow