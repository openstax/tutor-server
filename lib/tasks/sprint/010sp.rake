namespace :sprint do
  desc 'Sprint 10 Spaced Practice'
  task :'010sp' => :environment do |tt, args|
    require_relative 'sprint_010/sp.rb'
    result = Sprint010::Sp.call

    if result.errors.none?
      puts "success"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
