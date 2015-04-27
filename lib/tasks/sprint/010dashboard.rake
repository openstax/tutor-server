namespace :sprint do
  desc 'Sprint 10 dashboard api'
  task :'010dashboard' => :environment do |tt, args|
    require_relative 'sprint_010/dashboard.rb'
    result = Sprint010::Dashboard.call

    if result.errors.none?
      puts "success"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
