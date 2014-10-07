namespace :sprint do
  desc 'Set up a user with one reading task'
  task :'002', [:username] => [:environment] do |t, args|
    require 'sprint/sprint_002'
    args.with_defaults(username: SecureRandom.hex(4))
    Sprint002.call(args.username)
    puts "Created a user with username '#{args.username}' with one reading task"
  end
end