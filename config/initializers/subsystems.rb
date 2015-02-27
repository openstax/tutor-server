class Subsystem
  def initialize(name, the_module)
    @name = name
    @module = the_module
  end

  attr_reader :name, :module
end

#
# Identify the subsystems
#

subsystem_directories = Dir[File.join(Rails.root, "app/subsystems/*/")].sort

subsystems = subsystem_directories.collect do |dir|
  name = File.split(dir).last
  Subsystem.new(name, name.camelize.constantize)
end

#
# Extend has_many and belongs_to to be subsystem aware
#

ActiveRecord::Base.define_singleton_method(:set_options_for_subsystem_association) do |association_type, association_name, options|
  subsystem_option = options.delete(:subsystem)

  return if [:none, :ignore].include?(subsystem_option)

  module_name = self.name.deconstantize.underscore

  # ****** Temporary control to limit to only the Content subsystem ******
  return if module_name != "content"
  
  if subsystems.any?{|subsystem| subsystem.name == module_name}
    subsystem_option ||= module_name.to_sym
    options[:class_name] ||= "::#{subsystem_option.to_s.camelize}::#{association_name.to_s.camelize.singularize}"

    if :belongs_to == association_type
      options[:foreign_key] ||= "#{subsystem_option.to_s}_#{association_name.to_s.underscore}_id"
    elsif :has_many == association_type
      class_name = self.name.demodulize.underscore
      options[:foreign_key] ||= "#{subsystem_option.to_s}_#{class_name}_id"    
    end
  end
end

ActiveRecord::Base.singleton_class.send(:alias_method, :has_many_original, :has_many)
ActiveRecord::Base.singleton_class.send(:alias_method, :belongs_to_original, :belongs_to)

ActiveRecord::Base.define_singleton_method(:has_many) do |association_name, options={}|
  set_options_for_subsystem_association(:has_many, association_name, options)  
  has_many_original(association_name, options)
end

ActiveRecord::Base.define_singleton_method(:belongs_to) do |association_name, options={}|
  set_options_for_subsystem_association(:belongs_to, association_name, options)
  belongs_to_original(association_name, options)
end

#
# Load the subsystems
#

subsystems.each do |subsystem|
  Dir[File.join(Rails.root, "app/subsystems/#{subsystem.name}/*/**/*.rb")].each do |rb_file|
    path   = rb_file.gsub('.rb', '')
    symbol = File.split(path).last.camelize.to_sym
    subsystem.module.autoload symbol, path 
  end
  
  subsystem.module.define_singleton_method(:table_name_prefix) do
    "#{subsystem.name.underscore}_"
  end
end

