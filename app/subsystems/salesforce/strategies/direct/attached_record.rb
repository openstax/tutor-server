module Salesforce
  module Strategies
    module Direct
      class AttachedRecord < Entity

        wraps ::Salesforce::Models::AttachedRecord
        exposes :all, :find, :preload, from_class: ::Salesforce::Models::AttachedRecord
        exposes :salesforce_object, :attached_to, :attached_to_class_name, :attached_to_id

      end
    end
  end
end
