module ActiveRecord
  class Base
    class << self
      # https://github.com/zdennis/activerecord-import/issues/162
      # Like the import method, but raises RecordInvalid if a record fails to validate
      def import!(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        args.push(options.merge(all_or_none: true))
        result = import(*args)
        failed_instances = result.failed_instances
        raise(RecordInvalid.new(failed_instances.first)) if failed_instances.any?
        result
      end

      # Patch to make import_helper read attributes after typecast
      # (fixes issues with serializables and enums)
      def import_helper( *args )
        options = { :validate=>true, :timestamps=>true, :primary_key=>primary_key }
        options.merge!( args.pop ) if args.last.is_a? Hash

        is_validating = options[:validate]
        is_validating = true unless options[:validate_with_context].nil?

        # assume array of model objects
        if args.last.is_a?( Array ) and args.last.first.is_a? ActiveRecord::Base
          if args.length == 2
            models = args.last
            column_names = args.first
          else
            models = args.first
            column_names = self.column_names.dup
          end

          array_of_attributes = models.map do |model|
            # this next line breaks sqlite.so with a segmentation fault
            # if model.new_record? || options[:on_duplicate_key_update]
              column_names.map do |name|
                model.read_attribute(name.to_s)
              end
            # end
          end
          # supports empty array
        elsif args.last.is_a?( Array ) and args.last.empty?
          return ActiveRecord::Import::Result.new([], 0, []) if args.last.empty?
          # supports 2-element array and array
        elsif args.size == 2 and args.first.is_a?( Array ) and args.last.is_a?( Array )
          column_names, array_of_attributes = args
        else
          raise ArgumentError.new( "Invalid arguments!" )
        end

        # dup the passed in array so we don't modify it unintentionally
        array_of_attributes = array_of_attributes.dup

        # Force the primary key col into the insert if it's not
        # on the list and we are using a sequence and stuff a nil
        # value for it into each row so the sequencer will fire later
        if !column_names.include?(primary_key) && connection.prefetch_primary_key? && sequence_name
           column_names << primary_key
           array_of_attributes.each { |a| a << nil }
        end

        # record timestamps unless disabled in ActiveRecord::Base
        if record_timestamps && options.delete( :timestamps )
           add_special_rails_stamps column_names, array_of_attributes, options
        end

        return_obj = if is_validating
          import_with_validations( column_names, array_of_attributes, options )
        else
          (num_inserts, ids) = import_without_validations_or_callbacks( column_names, array_of_attributes, options )
          ActiveRecord::Import::Result.new([], num_inserts, ids)
        end

        if options[:synchronize]
          sync_keys = options[:synchronize_keys] || [self.primary_key]
          synchronize( options[:synchronize], sync_keys)
        end
        return_obj.num_inserts = 0 if return_obj.num_inserts.nil?

        # if we have ids, then set the id on the models and mark the models as clean.
        if support_setting_primary_key_of_imported_objects?
          set_ids_and_mark_clean(models, return_obj)

          # if there are auto-save associations on the models we imported that are new, import them as well
          if options[:recursive]
            import_associations(models, options)
          end
        end

        return_obj
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
