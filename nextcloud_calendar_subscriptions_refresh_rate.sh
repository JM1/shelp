#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Change refresh rate of calendar subscriptions in Nextcloud
#
# Refs.:
# [1] https://docs.nextcloud.com/server/19/admin_manual/groupware/calendar.html
# [2] https://stackoverflow.com/questions/17152251/specifying-name-description-and-refresh-interval-in-ical-ics-format
# [3] https://stackoverflow.com/questions/538081/set-update-limits-on-icalendar-feed
# [4] https://en.wikipedia.org/wiki/ICalendar#Calendar_extensions
# [5] https://www.php.net/manual/dateinterval.construct.php

# "Calendar subscriptions are cached on server and refreshed periodically.
#  The default refresh rate is of one week, unless the subscription itself
#  tells otherwise." [1]

# NOTE: Instead of changing the default refresh rate, it might be a better idea
#       to change the subscription's own refresh rate by adding or changing its
#       "X-PUBLISHED-TTL" [2][3][4] or "REFRESH-INTERVAL" [3] fields.

cd /var/www/nextcloud/
sudo -u www-data php occ config:list
sudo -u www-data php occ config:app:get dav calendarSubscriptionRefreshRate
sudo -u www-data php occ config:app:set dav calendarSubscriptionRefreshRate --value "P1D"
# "Where the value is a DateInterval [5], for instance with the above command
#  all of the Nextcloud instance’s calendars would be refreshed every day." [1]
