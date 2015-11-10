module Salesforce
  module Strategies
    module Direct
      class AttachedRecord < Entity

        wraps ::Salesforce::Models::AttachedRecord
        exposes :all, :find, from_class: ::Salesforce::Models::AttachedRecord

        class << self
          alias_method :entity_all, :all
          def all
            entity_all.collect do |entity|
              ::Salesforce::AttachedRecord.new(strategy: entity)
            end
          end

          alias_method :entity_find, :find
          def find(*args)
            ::Salesforce::AttachedRecord.new(strategy: entity_find(*args))
          end
        end

        def record
          repository.salesforce_class_name.constantize.find(repository.salesforce_id)
        end

        def attached_to
          GlobalID::Locator.locate repository.tutor_gid
        end

      end
    end
  end
end
