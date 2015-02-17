namespace :sprint do
  desc 'Set up a user with a reading task with fake reading and exercise content'
  task :'006beta', [:username] => [:environment] do |t, args|
    args.with_defaults(username: SecureRandom.hex(4))
    result = Sprint006::Beta.call(username_or_user: args.username)

    if result.errors.none?
      puts "Created a user with username '#{args.username}' with the sprint scenario"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end