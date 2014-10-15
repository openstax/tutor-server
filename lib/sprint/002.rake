namespace :sprint do
  desc 'Set up a user with one reading task'
  task :'002', [:username] => [:environment] do |t, args|
    require 'sprint/sprint_002'
    args.with_defaults(username: SecureRandom.hex(4))
    result = Sprint002.call(args.username)

    if result.errors.none?
      puts "Created a user with username '#{args.username}' with one reading and one interactive task"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end