module Salesforce
  module Strategies
    module Direct
      class AttachedRecord < Entity

        wraps ::Salesforce::Models::AttachedRecord
        exposes :all, :find, from_class: ::Salesforce::Models::AttachedRecord

        class << self
          alias_method :entity_all, :all
          def all
            Salesforce::Models::AttachedRecord.all.load_salesforce_objects.map do |entity|
              ::Salesforce::AttachedRecord.new(strategy: entity.wrap)
            end
          end

          alias_method :entity_find, :find
          def find(*args)
            ::Salesforce::AttachedRecord.new(strategy: entity_find(*args))
          end
        end

        def record
          repository.salesforce_object
        end

        def attached_to
          @attached_to ||= GlobalID::Locator.locate repository.tutor_gid
        end

      end
    end
  end
end
