bundle_command = ENV['BUNDLE_COMMAND'] || 'bundle exec'

set :bundle_command, bundle_command
set :runner_command, "#{bundle_command} rails runner"

every 1.minute do
  rake 'openstax:accounts:sync:all'
  rake 'openstax:biglearn:clues:update:recent'
end

every 1.day, at: '3:00 AM' do
  rake 'openstax:biglearn:clues:update:all'
end

every 1.hour do
  runner "OpenStax::RescueFrom.this{ ImportSalesforceCourses.call }"
end

every 1.day, at: '2:00 AM' do
  runner "OpenStax::RescueFrom.this{ UpdateSalesforceStats.call }"
end
