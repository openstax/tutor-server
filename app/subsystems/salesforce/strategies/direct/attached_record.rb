module Salesforce
  module Strategies
    module Direct
      class AttachedRecord < Entity

        wraps ::Salesforce::Models::AttachedRecord
        exposes :all, :find, :preload, from_class: ::Salesforce::Models::AttachedRecord
        exposes :salesforce_object, :attached_to

        alias_method :record, :salesforce_object

      end
    end
  end
end
