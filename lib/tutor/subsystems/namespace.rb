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

    def require_all
      each_file{| path | require path }
    end

    private

    def each_file
      Pathname.glob( path.join("**/*.rb") ){ |path| yield path }
    end

    def configure_module_settings

      namespace.define_singleton_method(:table_name_prefix) do
        "#{name.underscore}_"
      end

      # routines and models are namespaced directly under the module,
      # setup explicit autoload mappings in order to support them
      each_file do | path |
        symbol = path.basename('.rb').to_s.camelize.to_sym
        namespace.autoload symbol, path.to_s
      end
    end

  end
end
