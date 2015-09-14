set :bundle_command, ENV['BUNDLE_COMMAND'] || 'bundle exec'

every 1.minute do
  rake 'openstax:accounts:sync:all'
end
