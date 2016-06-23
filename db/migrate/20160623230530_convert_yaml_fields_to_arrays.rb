class ConvertYamlFieldsToArrays < ActiveRecord::Migration
  FIELDS_TO_MIGRATE = {
    'Content::Models::Chapter'        => { book_location: :integer },
    'Content::Models::Page'           => { book_location: :integer },
    'Content::Models::Pool'           => { content_exercise_ids: :integer },
    'Legal::Models::TargetedContract' => { masked_contract_names: :string },
    'Tasks::Models::TaskStep'         => { labels: :string },
    'Tasks::Models::TaskedReading'    => { book_location: :integer }
  }

  def up
    FIELDS_TO_MIGRATE.each do |class_name, fields|
      klass = class_name.constantize
      table_name = klass.table_name

      fields.each do |field_name, type|
        rename_column table_name, field_name, "#{field_name}_old"
        add_column table_name, field_name, type, array: true, default: '{}'
      end

      klass.find_each do |model|
        fields.each do |field_name, type|
          yaml = model.read_attribute_before_type_cast("#{field_name}_old") || [].to_yaml
          model.send "#{field_name}=", YAML.load(yaml)
        end

        model.save!
      end

      fields.each do |field_name, type|
        remove_column table_name, "#{field_name}_old"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
