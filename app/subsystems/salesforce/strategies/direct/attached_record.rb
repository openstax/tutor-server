module Salesforce
  module Strategies
    module Direct
      class AttachedRecord < Entity

        wraps ::Salesforce::Models::AttachedRecord
        exposes :salesforce_object, :salesforce_id, :attached_to, :attached_to_class_name, :attached_to_id

        def self.all
          models = ::Salesforce::Models::AttachedRecord.all
          models.map{|model| ::Salesforce::AttachedRecord.new(strategy: new(model))}
        end

        def self.find(*args)
          ::Salesforce::AttachedRecord.new(
            strategy: new(::Salesforce::Models::AttachedRecord.find(*args))
          )
        end

        def self.preload(*args)
          models = ::Salesforce::Models::AttachedRecord.preload(*args)
          models.map{|model| ::Salesforce::AttachedRecord.new(strategy: new(model))}
        end

      end
    end
  end
end
