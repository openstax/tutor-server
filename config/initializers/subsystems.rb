Dir[File.join(Rails.root, "app/subsystems/*/")].sort.each do |ss_root_dir|
  module_name = File.split(ss_root_dir).last
  a_module = module_name.camelcase.constantize

  Dir[File.join(Rails.root, "app/subsystems/#{module_name}/*/**/*.rb")].each do |rb_file|
    path   = rb_file.gsub('.rb', '')
    symbol = File.split(path).last.camelize.to_sym
    a_module.autoload symbol, path 
  end
  
  a_module.define_singleton_method(:table_name_prefix) do
    "#{module_name.underscore}_"
  end
end
