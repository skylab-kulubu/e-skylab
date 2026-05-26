package skylab.authz

import future.keywords.if
import future.keywords.in

import data.skylab.seasons
import data.skylab.users
import data.skylab.events
import data.skylab.event_types
import data.skylab.competitors
import data.skylab.media
import data.skylab.sessions
import data.skylab.ticket
import data.skylab.event_day
import data.skylab.certificate
import data.skylab.announcements
import data.skylab.applications
import data.skylab.content

default allow = false

allow if {
    input.resource.type == "SEASON"
    seasons.allow
}

allow if {
    input.resource.type == "USER"
    users.allow
}

allow if {
    input.resource.type == "EVENT"
    events.allow
}

allow if {
    input.resource.type == "EVENT_TYPE"
    event_types.allow
}

allow if {
    input.resource.type == "COMPETITOR"
    competitors.allow
}

allow if {
    input.resource.type == "MEDIA"
    media.allow
}

allow if {
    input.resource.type == "SESSION"
    sessions.allow
}

allow if {
    input.resource.type == "TICKET"
    ticket.allow
}

allow if {
    input.resource.type == "EVENT_DAY"
    event_day.allow
}

allow if {
    input.resource.type == "CERTIFICATE"
    certificate.allow
}

allow if {
    input.resource.type == "ANNOUNCEMENT"
    announcements.allow
}

allow if {
    input.resource.type == "APPLICATION"
    applications.allow
}

allow if {
    input.resource.type == "CONTENT_ITEM"
    content.allow
}
