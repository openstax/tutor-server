require_relative 'subsystems/association_extensions'

module Tutor
  module SubSystems
    mattr_accessor :valid_namespaces

    # called by the association_extensions to determine if a namespace should be extended
    def self.valid_name?(name)
      name.present? && (valid_namespaces.empty? || valid_namespaces.include?(name))
    end
  end

  SubSystems.valid_namespaces = []
end
