class ConvertYamlFieldsToJson < ActiveRecord::Migration
  FIELDS_TO_MIGRATE = {
    'Content::Models::Map' => {
      exercise_id_to_page_id_map: {},
      page_id_to_page_id_map: {},
      page_id_to_pool_type_exercise_ids_map: {}
    },
    'Tasks::Models::CourseAssistant' => { settings: {}, data: {} },
    'Tasks::Models::TaskStep' => { related_content: [] }
  }

  def up
    FIELDS_TO_MIGRATE.each do |class_name, fields|
      klass = class_name.constantize
      table_name = klass.table_name

      klass.find_each do |model|
        fields.each do |field_name, default|
          yaml = model.read_attribute_before_type_cast(field_name) || default.to_yaml
          model.send "#{field_name}=", YAML.load(yaml)
        end

        model.save!
      end

      fields.each do |field_name, default|
        change_column_default table_name, field_name, default.to_json
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
