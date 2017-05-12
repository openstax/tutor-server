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
  runner "OpenStax::RescueFrom.this{ GetSalesforceBookNames.call(true) }"
  runner "OpenStax::RescueFrom.this{ PushSalesforceCourseStats.call(allow_error_email: true) }"
end

every 30.minutes do
  rake 'refresh_cc_stats_view'
end
