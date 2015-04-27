require 'factory_girl_rails'

namespace :sprint do
  desc 'Sprint 10 Mixed iReading and Homework'
  task :'010mix' => :environment do |tt, args|
    require_relative 'sprint_010/mix.rb'
    result = Sprint010::Mix.call

    if result.errors.none?
      puts "Success!"
    else
      result.errors.each{ |error| puts "Error: " + Lev::ErrorTranslator.translate(error) }
    end
  end
end
