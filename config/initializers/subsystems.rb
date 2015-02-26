domain_files         = Dir[File.join(Rails.root, "app/subsystems/domain/**/*.rb")].sort
entity_files         = Dir[File.join(Rails.root, "app/subsystems/entity/**/*.rb")].sort - domain_files
subsystem_root_files = Dir[File.join(Rails.root, "app/subsystems/*/*.rb")].sort - domain_files - entity_files
subsystem_files      = Dir[File.join(Rails.root, "app/subsystems/**/*.rb")].sort - domain_files - entity_files - subsystem_root_files

[entity_files, subsystem_root_files, subsystem_files, domain_files].flatten.each do |file|
  # puts "=== requiring #{file} ==="
  ActiveSupport.require_or_load file
end
