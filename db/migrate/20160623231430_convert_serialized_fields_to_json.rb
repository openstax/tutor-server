class ConvertSerializedFieldsToJson < ActiveRecord::Migration
  FIELDS_TO_MIGRATE = {
    'Content::Models::Book'           => { reading_processing_instructions: [] },
    'Content::Models::Chapter'        => { book_location: [] },
    'Content::Models::Map' => {
      exercise_id_to_page_id_map: {},
      page_id_to_page_id_map: {},
      page_id_to_pool_type_exercise_ids_map: {},
      validity_error_messages: []
    },
    'Content::Models::Page'           => { book_location: [], fragments: [], snap_labs: [] },
    'Content::Models::Pool'           => { content_exercise_ids: [] },
    'Legal::Models::TargetedContract' => { masked_contract_names: [] },
    'Tasks::Models::CourseAssistant'  => { settings: {}, data: {} },
    'Tasks::Models::Task'             => { spy: {} },
    'Tasks::Models::TaskedReading'    => { book_location: [] },
    'Tasks::Models::TaskStep'         => {
      related_content: [],
      related_exercise_ids: [],
      labels: []
    }
  }

  def up
    FIELDS_TO_MIGRATE.each do |class_name, fields|
      klass = class_name.constantize
      table_name = klass.table_name

      fields.each do |field_name, default|
        rename_column table_name, field_name, "#{field_name}_old"
        add_column table_name, field_name, :text, null: false, default: default.to_json
      end

      relation = klass.find_each(batch_size: 100) do |model|
        attributes = {}

        fields.each do |field_name, default|
          old_value = model.send("#{field_name}_old")

          new_value = case old_value
          when Array, Hash
            old_value
          when String
            YAML.load(old_value)
          else
            default
          end

          attributes[field_name] = new_value
        end

        model.update_columns attributes
      end

      fields.each{ |field_name, default| remove_column table_name, "#{field_name}_old" }
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
