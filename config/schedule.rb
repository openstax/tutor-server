# Server time is UTC; times below are interpreted that way.
# Ideally we'd have a better way to specify times relative to Central
# time, independent of the server time.  Maybe there's something here:
#   * https://github.com/javan/whenever/issues/481
#   * https://github.com/javan/whenever/pull/239

every 1.minute { rake 'cron:minute' }

every 10.minutes do
  runner "OpenStax::RescueFrom.this { CourseProfile::BuildPreviewCourses.call }"
end

# These hours are chosen to allow plenty of space between them
# and to place them in low traffic hours for US timezones
every 1.day, at: '8 AM' { rake 'cron:day' }  # Midnight-1AM Pacific/2-3AM Central/3-4AM Eastern

every 1.month, at: '10 AM' { rake 'cron:month' } # 5-6AM Eastern/4-5AM Central/2-3AM Pacific
