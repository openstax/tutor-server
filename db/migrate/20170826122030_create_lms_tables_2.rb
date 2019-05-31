class CreateLmsTables2 < ActiveRecord::Migration[4.2]
  def change
    create_table :lms_tool_consumers do |t|
      t.string :guid, null: false, index: true
      t.string :product_family_code
      t.string :version
      t.string :name
      t.string :description
      t.string :url
      t.string :contact_email
    end

    create_table :lms_contexts do |t|
      t.string :lti_id, null: false, index: true
      t.references :lms_tool_consumer, null: false, index: true,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :course_profile_course, null: false, index: true,
                                           foreign_key: { on_update: :cascade, on_delete: :cascade }
    end

    create_table :lms_course_grade_callbacks do |t|
      t.string :result_sourcedid, null: false
      t.string :outcome_url, null: false
      t.references :course_membership_student, null: false,
                                               foreign_key: { on_update: :cascade, on_delete: :cascade },
                                               index: { name: :course_grade_callbacks_on_student }
    end

    add_index :lms_course_grade_callbacks, [:result_sourcedid, :outcome_url],
              unique: true, name: :course_grade_callback_result_outcome

    create_table :lms_trusted_launch_data do |t|
      t.json :request_params
      t.string :request_url
    end
  end
end
