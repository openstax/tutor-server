set :bundle_command, ENV['BUNDLE_COMMAND'] || 'bundle exec'

every 1.minute do
  rake 'openstax:accounts:sync:all'
  rake 'openstax:biglearn:update_recent_clues'
end

every 1.day do
  rake 'openstax:biglearn:update_all_clues'
end
