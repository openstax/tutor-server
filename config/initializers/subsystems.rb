Dir[File.join(Rails.root, "app/subsystems/*/*.rb")] \
.select{|f| f !~ %r{app/subsytems/domain/}} \
.select{|f| f =~ %r{app/subsystems/(.*?)/\1}}
.sort.each do |ss_root_file|
  # puts "ss_root_file: #{ss_root_file}"
  ActiveSupport.require_or_load ss_root_file
end
