class ConvertArrayAndJsonbFieldsToSerializedJson < ActiveRecord::Migration
  FIELDS_TO_MIGRATE = {
    'Tasks::Models::TaskStep' => :related_exercise_ids,
    'Content::Models::Book' => :reading_processing_instructions,
    'Content::Models::Map' => :validity_error_messages,
    'Content::Models::Page' => [:fragments, :snap_labs]
  }

  def up
    FIELDS_TO_MIGRATE.each do |class_name, field_names|
      klass = class_name.constantize
      table_name = klass.table_name
      field_names = [field_names].flatten

      field_names.each do |field_name|
        rename_column table_name, field_name, "#{field_name}_old"
        add_column table_name, field_name, :text, null: false, default: '[]'
      end

      klass.find_each do |model|
        field_names.each do |field_name|
          array = model.send("#{field_name}_old") || []
          model.send "#{field_name}=", array
        end

        model.save!
      end

      field_names.each{ |field_name| remove_column table_name, "#{field_name}_old" }
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
