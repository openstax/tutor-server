require_relative 'subsystems/association_extensions'
require_relative 'subsystems/namespace'
require 'singleton'
require 'forwardable'
module Tutor

  module SubSystems

    # Attach a few methods from the Definitions singleton to the SubSystems module
    # This way they can be called in a more natural fasion directly
    class << self
      extend Forwardable
      def_delegators :"Tutor::SubSystems::Definitions.instance", :configure, :valid_name?, :path
    end

    # Record information about all the subsystems that are defined
    # Contains a list of each namespace that's defined as a subsystem
    class Definitions
      include Singleton
      include Enumerable

      attr_reader :path
      # Initialize with empty definitions.
      # This way it doesn't blow up if "configure" isn't called
      def initialize
        @systems = @limit_to = []
      end

      # Root directory to search for subsystems
      # limit_to will restrict operations on only those subsystems.
      # if limit_to is nil (the default), it will default to all directories under root
      def configure(path:nil, limit_to:[])
        @path = path
        paths = Pathname.glob( path.join("*") )

        ## Removes the subsystems path from the Rail's loading conventions
        # Each namespace will re-establish it's mappings later when it's created
        Rails.application.config.autoload_paths   -= [ path.to_s ]
        Rails.application.config.eager_load_paths -= [ path.to_s ]

        # Setup a Namespace for each directory found under our root path
        @systems = paths.each_with_object([]) do |subpath, collection|
          collection << SubSystems::Namespace.new(subpath.basename.to_s) if subpath.directory?
        end
        @limit_to = limit_to.present? ? limit_to : @systems.map(&:name)
      end

      def each(&block)
        @systems.each(&block)
      end
      # returns true if the subsystem name is included in the list of valid subsystems
      # either by use of limit_to or by detecting a directory with that name
      def valid_name?(name)
        @limit_to.include?(name)
      end

    end

  end

end
