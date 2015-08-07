module ActiveRecord
  class Base
    class << self
      # https://github.com/zdennis/activerecord-import/issues/162
      # Like the import method, but raises RecordInvalid on failure
      def import!(*args)
        result = import(*args)
        failed_instances = result.failed_instances
        raise(RecordInvalid.new(failed_instances.first)) if failed_instances.any?
        result
      end

      private

      # https://github.com/zdennis/activerecord-import/blob/6c06b3ceb53f83e1ce930eab35cdd4b6375c57ca/lib/activerecord-import/import.rb#L444
      # Patch to make recursive imports work with singular associations
      def find_associated_objects_for_import(associated_objects_by_class, model)
        associated_objects_by_class[model.class.name]||={}

        model.class.reflect_on_all_autosave_associations.each do |association_reflection|
          associated_objects_by_class[model.class.name][association_reflection.name]||=[]

          association = model.association(association_reflection.name)
          association.loaded!

          objects = model.send(association_reflection.name)
          changed_objects = [objects].flatten.compact.select{|a| a.new_record? || a.changed?}
          changed_objects.each do |child|
            child.send("#{association_reflection.foreign_key}=", model.id)
          end
          associated_objects_by_class[model.class.name][association_reflection.name].concat changed_objects
        end
        associated_objects_by_class
      end
    end
  end
end
