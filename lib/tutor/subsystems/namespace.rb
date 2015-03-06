module Tutor::SubSystems

  # Defines a subsystem.
  # currently tracks the name, it's path,
  # and the namespace (a Ruby Module) that it defineds
  class Namespace
    attr_reader :name, :path, :namespace
    def initialize(name)
      @name   = name
      @path = Tutor::SubSystems.path.join(name)
      @namespace = name.camelize.constantize
      configure_module_settings
    end

    private

    def configure_module_settings
      namespace.define_singleton_method(:table_name_prefix) do
        "#{name.underscore}_"
      end

      # Add the subsystem's path to the autoload search paths
      # This will allow objects who's namespace matches the directory tree to autoload
      # i.e. course_profile/api/get_all_profiles.rb => CourseProfile::Api::GetAllProfiles
      Rails.application.config.autoload_paths += [path.relative_path_from(Rails.root)]

      # routines and models are namespaced directly under the module,
      # setup explicit autoload mappings in order to support them
      Pathname.glob( path.join("{routines,models}/*.rb") ) do | path |
        symbol = path.basename('.rb').to_s.camelize.to_sym
        namespace.autoload symbol, path.to_s
      end

    end
  end
end
