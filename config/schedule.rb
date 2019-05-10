bundle_command = ENV['BUNDLE_COMMAND'] || 'bundle exec'

set :bundle_command, bundle_command
set :runner_command, "#{bundle_command} rails runner"

# Server time is UTC; times below are interpreted that way.
# Ideally we'd have a better way to specify times relative to Central
# time, independent of the server time.  Maybe there's something here:
#   * https://github.com/javan/whenever/issues/481
#   * https://github.com/javan/whenever/pull/239

every 1.minute do
  rake 'openstax:accounts:sync:all'
end

every 1.day, at: '8:30 AM' do  # ~ 2:30am central
  runner "OpenStax::RescueFrom.this { GetSalesforceBookNames.call(true) }"
  runner "OpenStax::RescueFrom.this { PushSalesforceCourseStats.call(allow_error_email: true) }"
end

every 1.day, at: '10:30 AM' do
  runner "OpenStax::RescueFrom.this { Lms::Models::TrustedLaunchData.cleanup }"
end

every 1.hour do
  runner "OpenStax::RescueFrom.this { CourseProfile::BuildPreviewCourses.call }"
end

every 1.month, at: '9 AM' do  # ~ 3am central
  runner "OpenStax::RescueFrom.this { Jobba.cleanup }"
end

every 1.hour do
  runner "OpenStax::RescueFrom.this { Research::UpdateStudyActivations.call }"
end
