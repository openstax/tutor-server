namespace :sprint do
  desc 'Sprint 7'
  task :'007', [:username] => :environment do |t, args|
    require_relative 'sprint_007/main.rb'
    args.with_defaults(username: SecureRandom.hex(4))
    result = Sprint007::Main.call(username_or_user: args.username)

    if result.errors.none?
      puts "Success!"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
