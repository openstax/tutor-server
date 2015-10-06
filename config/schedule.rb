set :bundle_command, ENV['BUNDLE_COMMAND'] || 'bundle exec'

every 1.minute do
  rake 'openstax:accounts:sync:all'
  rake 'openstax:biglearn:clues:update:recent'
end

every 1.day, at: '3:00 AM' do
  rake 'openstax:biglearn:clues:update:all'
end
