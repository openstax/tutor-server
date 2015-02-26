domain_files         = Dir[File.join(Rails.root, "app/subsystems/domain/**/*.rb")]
entity_files         = Dir[File.join(Rails.root, "app/subsystems/entity/**/*.rb")] - domain_files
subsystem_root_files = Dir[File.join(Rails.root, "app/subsystems/*/*.rb")] - domain_files - entity_files
subsystem_files      = Dir[File.join(Rails.root, "app/subsystems/**/*.rb")] - domain_files - entity_files - subsystem_root_files

[entity_files, subsystem_root_files, subsystem_files, domain_files].flatten.each do |file|
  puts "=== requiring #{file} ==="
  ActiveSupport.require_or_load file
end
