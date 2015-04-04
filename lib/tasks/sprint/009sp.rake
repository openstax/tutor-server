namespace :sprint do
  desc 'Sprint 9 Spaced Practice'
  task :'009sp' => :environment do |tt, args|
    require_relative 'sprint_009/sp.rb'
    result = Sprint009::Sp.call

    if result.errors.none?
      puts "success"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
