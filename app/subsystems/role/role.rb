module Role
  extend ActiveSupport::Autoload

  module_name = Module.nesting.first.to_s.underscore
  Dir[File.join(Rails.root, "app/subsystems/#{module_name}/*/**/*.rb")].each do |rb_file|
    path   = rb_file.gsub('.rb', '')
    symbol = File.split(path).last.camelize.to_sym
    autoload symbol, path 
  end

  def self.table_name_prefix
    'role_'
  end
end
