bundle_command = ENV['BUNDLE_COMMAND'] || 'bundle exec'

set :bundle_command, bundle_command
set :runner_command, "#{bundle_command} rails runner"

# Server time is UTC; times below are interpreted that way.
# Ideally we'd have a better way to specify times relative to Central
# time, independent of the server time.  Maybe there's something here:
#   * https://github.com/javan/whenever/issues/481
#   * https://github.com/javan/whenever/pull/239

every 1.minute do
  rake 'openstax:accounts:sync:accounts'
  rake 'delayed:heartbeat:delete_timed_out_workers'
end

every 10.minutes do
  runner "OpenStax::RescueFrom.this { CourseProfile::BuildPreviewCourses.call }"
end

every 1.hour do
  runner "OpenStax::RescueFrom.this { Research::UpdateStudyActivations.call }"
end

every 1.day, at: '8:30 AM' do  # ~ 2:30am central
  runner "OpenStax::RescueFrom.this { GetSalesforceBookNames.call(true) }"
  runner "OpenStax::RescueFrom.this { PushSalesforceCourseStats.call }"
end

every 1.day, at: '10:30 AM' do
  runner "OpenStax::RescueFrom.this { Lms::Models::TrustedLaunchData.cleanup }"
end

every 1.week do
  runner "OpenStax::RescueFrom.this { Stats::Generate.call start_at: 1.week.ago.beginning_of_week }"
end

every 1.month, at: '9 AM' do  # ~ 3am central
  runner "OpenStax::RescueFrom.this { Jobba.cleanup }"
end

# On the 1st of every odd month (normal courses only end on January, March, July, September)
every 2.month do
  runner 'OpenStax::RescueFrom.this { Tasks::FreezeEndedCourseTeacherPerformanceReports.call }'
end
