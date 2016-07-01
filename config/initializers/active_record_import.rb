module ActiveRecord
  class Base
    class << self
      # Patch to make import_helper read attributes after typecast
      # (fixes issues with serializables and enums)
      def import_helper( *args )
        options = { validate: true, timestamps: true, primary_key: primary_key }
        options.merge!( args.pop ) if args.last.is_a? Hash

        # Don't modify incoming arguments
        if options[:on_duplicate_key_update]
          options[:on_duplicate_key_update] = options[:on_duplicate_key_update].dup
        end

        is_validating = options[:validate]
        is_validating = true unless options[:validate_with_context].nil?

        # assume array of model objects
        if args.last.is_a?( Array ) && args.last.first.is_a?(ActiveRecord::Base)
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
        elsif args.last.is_a?( Array ) && args.last.empty?
          return ActiveRecord::Import::Result.new([], 0, [])
          # supports 2-element array and array
        elsif args.size == 2 && args.first.is_a?( Array ) && args.last.is_a?( Array )
          column_names, array_of_attributes = args
          array_of_attributes = array_of_attributes.map(&:dup)
        else
          raise ArgumentError, "Invalid arguments!"
        end

        # dup the passed in array so we don't modify it unintentionally
        column_names = column_names.dup

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
          if models
            import_with_validations( column_names, array_of_attributes, options ) do |failed|
              models.each_with_index do |model, i|
                model = model.dup if options[:recursive]
                next if model.valid?(options[:validate_with_context])
                model.send(:raise_record_invalid) if options[:raise_error]
                array_of_attributes[i] = nil
                failed << model
              end
            end
          else
            import_with_validations( column_names, array_of_attributes, options )
          end
        else
          (num_inserts, ids) = import_without_validations_or_callbacks( column_names, array_of_attributes, options )
          ActiveRecord::Import::Result.new([], num_inserts, ids)
        end

        if options[:synchronize]
          sync_keys = options[:synchronize_keys] || [primary_key]
          synchronize( options[:synchronize], sync_keys)
        end
        return_obj.num_inserts = 0 if return_obj.num_inserts.nil?

        # if we have ids, then set the id on the models and mark the models as clean.
        if support_setting_primary_key_of_imported_objects?
          set_ids_and_mark_clean(models, return_obj)

          # if there are auto-save associations on the models we imported that are new, import them as well
          import_associations(models, options.dup) if options[:recursive]
        end

        return_obj
      end
    end
  end
end
