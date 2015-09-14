set :bundle_command, '/usr/local/bin/rbenv exec bundle exec'

every 1.minute do
  rake 'openstax:accounts:sync:all'
end
