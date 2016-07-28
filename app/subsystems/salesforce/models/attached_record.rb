module Salesforce
  module Models
    class AttachedRecord < Tutor::SubSystems::BaseModel
      # recovering SF linkage info is hard if not impossible, so soft delete
      acts_as_paranoid

      MAX_IDS_PER_REQUEST = 500

      wrapped_by ::Salesforce::Strategies::Direct::AttachedRecord

      validates :tutor_gid, presence: true
      validates :salesforce_class_name, presence: true
      validates :salesforce_id, presence: true

      def salesforce_class
        salesforce_class_name.constantize
      end

      attr_writer :salesforce_object, :attached_to

      def salesforce_object
        @salesforce_object ||= salesforce_class.find(salesforce_id)
      end

      def attached_to
        @attached_to ||= GlobalID::Locator.locate tutor_gid
      end

      def attached_to_class_name
        tutor_gid.match(/\/([^\/]*)\/\d+\Z/)[1]
      end

      def attached_to_id
        tutor_gid.match(/\/(\d+)\Z/)[1].to_i
      end

      def self.preload(what = :all)
        rel = all

        if [:all, :salesforce_objects].include?(what)
          rel = rel.group_by(&:salesforce_class_name)
                   .each do |salesforce_class_name, one_class_models|
            salesforce_class = salesforce_class_name.constantize
            salesforce_ids = one_class_models.map(&:salesforce_id)

            salesforce_objects = {}
            salesforce_ids.each_slice(MAX_IDS_PER_REQUEST) do |salesforce_ids|
              salesforce_objects.merge! salesforce_class.where(id: salesforce_ids)
                                                        .to_a.index_by(&:id)
            end

            one_class_models.each do |model|
              model.salesforce_object = salesforce_objects[model.salesforce_id]
            end
          end.values.flatten
        end

        if [:all, :attached_tos].include?(what)
          tutor_gids = rel.map(&:tutor_gid)
          attached_tos = GlobalID::Locator.locate_many tutor_gids
          rel = rel.each_with_index do |attached_record, index|
            attached_record.attached_to = attached_tos[index]
          end
        end

        rel
      end

    end
  end
end
