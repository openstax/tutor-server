module Salesforce
  module Models
    class AttachedRecord < Tutor::SubSystems::BaseModel

      wrapped_by ::Salesforce::Strategies::Direct::AttachedRecord

      validates :tutor_gid, presence: true
      validates :salesforce_class_name, presence: true
      validates :salesforce_id, presence: true

      def salesforce_class
        salesforce_class_name.constantize
      end

      attr_writer :salesforce_object

      def salesforce_object
        @salesforce_object ||= salesforce_class.find(salesforce_id)
      end

      def self.load_salesforce_objects
        all.group_by(&:salesforce_class_name).each do |salesforce_class_name, one_class_models|
          salesforce_class = salesforce_class_name.constantize
          salesforce_ids = one_class_models.map(&:salesforce_id)
          salesforce_objects = salesforce_class.where(id: salesforce_ids).all.index_by(&:id)

          one_class_models.each do |model|
            model.salesforce_object = salesforce_objects[model.salesforce_id]
          end
        end.values.flatten
      end

    end
  end
end
