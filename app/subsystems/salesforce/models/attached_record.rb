module Salesforce
  module Models
    class AttachedRecord < Tutor::SubSystems::BaseModel

      wrapped_by ::Salesforce::Strategies::Direct::AttachedRecord

      validates :tutor_gid, presence: true
      validates :salesforce_class_name, presence: true
      validates :salesforce_id, presence: true
    end
  end
end
