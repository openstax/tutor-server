namespace :sprint do
  desc 'Set up a user with a reading task with content from CNX and more real spaced practice'
  task :'006', [:username] => :environment do |t, args|
    require_relative 'sprint_006/main.rb'
    args.with_defaults(username: SecureRandom.hex(4))
    result = Sprint006::Main.call(username_or_user: args.username)

    if result.errors.none?
      puts "Created a user with username '#{args.username}' with the sprint scenario"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
