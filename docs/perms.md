# Permissions

Any app (frontend/backend/plugin) may create new permissions, but here is a list
of buldin ones. If possible use this ones, or if necesary, and may be useful to
be used by other users, add it here.

All permissions should be read as "I can XXX", for example "I can modify my own
user".

## Auth

auth.list -- Access to users, groups and users in groups lists
auth.modify_self -- Modify my own user
auth.modify_any  -- Modify any user
auth.create_user -- Create user
auth.create_token -- Creates an auth token
auth.info_any_user -- Can get info on any user

auth.modify_groups -- Creates/update/remove groups
auth.manage_groups -- Adds/removes users/permissions from groups

Temporary permissions:

auth.reset_password -- Given at the reset password action via email.

## Plugins

plugin -- Can start, stop and make calls into plugins. May have [plugin_id/cmd_id]
plugin.data -- Can access and modify plugin data. May have a [context]
plugin.install -- Can install new plugins into the system

## HTTP

http.port_to_websocket -- Allows to manage port to websocket mappings

## Project

project.add -- Add/remove serverboards
project.update -- Modify serverboard
project.delete -- Deletes serverboard
project.get -- Gets all info from serverboard

project.widget.add -- Can add widgets
project.widget.update -- Can update widgets

## Services

service.add -- Add/remove services
service.attach -- Attach/detach a service to an existing serverboard
service.update -- Modifies service configuration
service.delete -- Deletes services
service.info -- Gathers information about any service

## Event

event.emit -- Allow to emit events

## Action

action.trigger -- Can start triggers. May have trigger id.
action.watch   -- Can be notified when actions start/stop.

## Settings

settings.view -- View settings. Specific sections may have more permissions. It may have a [context] for specific settings to see.
settings.update -- Update settings.

settings.user.view -- View current user settings. May have [context].
settings.user.update -- Update current user settings
settings.user.view_all -- View settings of all users (admin)
settings.user.update_all -- Update settings of all users (admin)

## Notifications

notifications.notify -- Can notify current user. Needed for `notifications.notify_all`
notifications.notify_all -- Can notify any user. Needs `notifications.notify` permission.
notifications.list -- List notifications for current user.

## Rules

rules.update -- Can create/update/delete rules
rules.view -- View rules

## Issues

issues.view -- Can view issues
issues.add -- Can add issues
issues.update -- Can add updates to issues

## Other

debug -- Debug when in debug mode
logs.view -- View system logs. May contain sensitive information.
