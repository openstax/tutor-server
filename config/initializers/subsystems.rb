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

  # ****** Temporary control to limit to only the Content and CourseContent subsystem ******
  return if !%w(content course_content course_profile).include?(module_name)

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

##
## LOAD SUBSYSTEMS
##

##
## Remove .../app/subsystems from the eager load paths (which are used by autoload) to
## prevent confusion between rails file/symbol naming conventions.
##

Rails.application.config.eager_load_paths -= %W(#{Rails.application.config.root}/app/subsystems)

##
## Setup all the autoload symbol mappings for all subsystems.  This is done _before_ the
## requiring down below so that dependencies can be found.
##

subsystems.each do |ss|
  ## make ActiveRecord happy
  ss.module.define_singleton_method(:table_name_prefix) do
    "#{ss.name.underscore}_"
  end

  ## create a symbol --> file mapping for the normal ruby autoload
  Dir[File.join(Rails.root, "app/subsystems/#{ss.name}/**/*.rb")].sort.each do |rb_file|
    path   = rb_file.gsub('.rb', '')
    symbol = File.split(path).last.camelize.to_sym
    ss.module.autoload symbol, path
  end
end

##
## Require the files here and how to avoid confusion caused by rails trying
## to autoload them later.
##

Dir[File.join(Rails.root, "app/subsystems/**/*.rb")].sort.each do |rb_file|
  path   = rb_file.gsub('.rb', '')
  require path
end
