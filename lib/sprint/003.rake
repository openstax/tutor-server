namespace :sprint do
  desc 'Set up a user with one reading task, one simulation, one homework with manual, spaced, and biglearn exercises'
  task :'003', [:username] => [:environment] do |t, args|
    args.with_defaults(username: SecureRandom.hex(4))
    result = Sprint003::Main.call(username_or_user: args.username)

    if result.errors.none?
      puts "Created a user with username '#{args.username}' with three tasks"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end