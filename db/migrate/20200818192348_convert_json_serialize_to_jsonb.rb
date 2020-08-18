class ConvertJsonSerializeToJsonb < ActiveRecord::Migration[5.2]
  def up
    add_column :content_books, :rpijb, :jsonb, array: true, default: [], null: false
    Content::Models::Book.update_all(
      'rpijb = array(select json_array_elements(reading_processing_instructions::json))::jsonb[]'
    )
    remove_column :content_books, :reading_processing_instructions
    rename_column :content_books, :rpijb, :reading_processing_instructions

    change_column_default :content_maps, :exercise_id_to_page_id_map, nil
    change_column :content_maps, :exercise_id_to_page_id_map, :jsonb,
                  using: 'exercise_id_to_page_id_map::jsonb', default: {}, null: false

    change_column_default :content_maps, :page_id_to_page_id_map, nil
    change_column :content_maps, :page_id_to_page_id_map, :jsonb,
                  using: 'exercise_id_to_page_id_map::jsonb', default: {}, null: false

    change_column_default :content_maps, :page_id_to_pool_type_exercise_ids_map, nil
    change_column :content_maps, :page_id_to_pool_type_exercise_ids_map, :jsonb,
                  using: 'exercise_id_to_page_id_map::jsonb', default: {}, null: false

    add_column :content_maps, :vem, :string, array: true, default: [], null: false
    Content::Models::Map.update_all(
      'vem = array(select json_array_elements_text(validity_error_messages::json))'
    )
    remove_column :content_maps, :validity_error_messages
    rename_column :content_maps, :vem, :validity_error_messages

    add_column :content_pages, :sl, :jsonb, array: true, default: [], null: false
    add_column :content_pages, :bl, :integer, array: true, default: [], null: false
    Content::Models::Page.update_all(
      <<~UPDATE_SQL
        sl = array(select json_array_elements(snap_labs::json))::jsonb[],
        bl = array(select json_array_elements_text(book_location::json))::int[]
      UPDATE_SQL
    )
    remove_column :content_pages, :snap_labs
    remove_column :content_pages, :book_location
    rename_column :content_pages, :sl, :snap_labs
    rename_column :content_pages, :bl, :book_location

    add_column :legal_targeted_contracts, :mcn, :string, array: true, default: [], null: false
    Legal::Models::TargetedContract.update_all(
      'mcn = array(select json_array_elements_text(masked_contract_names::json))'
    )
    remove_column :legal_targeted_contracts, :masked_contract_names
    rename_column :legal_targeted_contracts, :mcn, :masked_contract_names

    change_column_default :tasks_course_assistants, :settings, nil
    change_column :tasks_course_assistants, :settings, :jsonb,
                  using: 'settings::jsonb', default: {}, null: false

    change_column_default :tasks_course_assistants, :data, nil
    change_column :tasks_course_assistants, :data, :jsonb,
                  using: 'data::jsonb', default: {}, null: false

    change_column_default :tasks_task_plans, :settings, nil
    change_column :tasks_task_plans, :settings, :jsonb,
                  using: 'settings::jsonb', default: {}, null: false

    add_column :tasks_task_steps, :rei, :integer, array: true, default: [], null: false
    add_column :tasks_task_steps, :l, :string, array: true, default: [], null: false
    Tasks::Models::TaskStep.update_all(
      <<~UPDATE_SQL
        rei = array(select json_array_elements_text(related_exercise_ids::json))::int[],
        l = array(select json_array_elements_text(labels::json))
      UPDATE_SQL
    )
    remove_column :tasks_task_steps, :related_exercise_ids
    remove_column :tasks_task_steps, :labels
    rename_column :tasks_task_steps, :rei, :related_exercise_ids
    rename_column :tasks_task_steps, :l, :labels

    change_column_default :tasks_task_steps, :spy, nil
    change_column :tasks_task_steps, :spy, :jsonb,
                  using: 'spy::jsonb', default: {}, null: false

    change_column_default :tasks_tasks, :spy, nil
    change_column :tasks_tasks, :spy, :jsonb, using: 'spy::jsonb', default: {}, null: false

    add_column :tasks_tasked_readings, :bl, :integer, array: true, default: [], null: false
    Tasks::Models::TaskedReading.update_all(
      'bl = array(select json_array_elements_text(book_location::json))::int[]'
    )
    remove_column :tasks_tasked_readings, :book_location
    rename_column :tasks_tasked_readings, :bl, :book_location

    change_column_default :user_profiles, :ui_settings, nil
    change_column :user_profiles, :ui_settings, :jsonb,
                  using: 'ui_settings::jsonb', default: {}, null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
