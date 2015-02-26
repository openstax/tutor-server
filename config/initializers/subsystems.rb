domain_files         = Dir[File.join(Rails.root, "app/subsystems/domain/**/*.rb")].sort
entity_files         = Dir[File.join(Rails.root, "app/subsystems/entity/**/*.rb")].sort - domain_files
subsystem_root_files = Dir[File.join(Rails.root, "app/subsystems/*/*.rb")].sort - domain_files - entity_files
subsystem_files      = Dir[File.join(Rails.root, "app/subsystems/**/*.rb")].sort - domain_files - entity_files - subsystem_root_files

# [entity_files, subsystem_root_files, subsystem_files, domain_files].flatten.each do |file|
#   puts "=== requiring #{file} ==="
#   ActiveSupport.require_or_load file
# end

# [subsystem_root_files].flatten.each do |file|
#   puts "=== requiring #{file} ==="
#   ActiveSupport.require_or_load file
# end

# puts "==== HERE ===="
# ss_dirnames = Dir[File.join(Rails.root, "app/subsystems/*/")] \
#                      .select{|f| f !~ %r{/domain/\z}}
# ss_dirnames.each do |ss_dirname|
#   puts "ss_dirname: #{ss_dirname}"

#   ss_basename = File.split(ss_dirname.to_s).last
#   puts "ss_basename: #{ss_basename}"

#   module_name = ss_basename.camelize
#   puts "module_name: #{module_name}"

#   rb_filenames = Dir[File.join(ss_dirname, "**/*.rb")]
#   rb_filenames.each do |rb_filename|
#     puts "  rb_filename: #{rb_filename}"
#     rb_basename = File.basename(rb_filename.to_s, ".rb")
#     puts "  rb_basename: #{rb_basename}"
#     symbol_name = rb_basename.camelize
#     puts "  symbol_name: #{symbol_name}"

#     autoload symbol_name.to_sym, rb_filename.gsub(".rb", "")
#   end
# end

module Role
  extend ActiveSupport::Autoload
  autoload :AddUserRole,     File.join(Rails.root, 'app/subsystems/role/routines/add_user_role')
  autoload :CreateUserRole,  File.join(Rails.root, 'app/subsystems/role/routines/create_user_role')
  autoload :GetUserRoles,    File.join(Rails.root, 'app/subsystems/role/routines/get_user_roles')
end
  # extend ActiveSupport::Autoload
  # autoload :AddUserRole, 'role/routines/add_user_role'
  # autoload :CreateUserRole, 'role/routines/create_user_role'
