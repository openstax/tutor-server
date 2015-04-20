namespace :sprint do
  desc 'Sprint 10 events api'
  task :'010events' => :environment do |tt, args|
    require_relative 'sprint_010/events.rb'
    result = Sprint010::Events.call

    if result.errors.none?
      puts "success"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
