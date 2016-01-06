require 'export_data'

desc 'Exports data for research purposes'
task :export_data, [] => :environment do
  filepath = ExportData.call
  puts "Wrote exported data to #{filepath}"
end

