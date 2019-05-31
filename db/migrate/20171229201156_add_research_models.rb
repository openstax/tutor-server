class AddResearchModels < ActiveRecord::Migration[4.2]
  def change
    create_table :research_studies do |t|
      t.string :name,                           null: false
      t.text :description

      t.timestamps                              null: false
    end

    create_table :research_study_courses do |t|
      t.references :research_study,             null: false, index: true,
                                                foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :course_profile_course,      null: false, index: true,
                                                foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps                              null: false
    end

    add_index :research_study_courses, [:course_profile_course_id, :research_study_id], unique: true,
              name: :research_study_courses_on_course_and_study

    create_table :research_survey_plans do |t|
      t.references :research_study,             null: false, index: true,
                                                foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :title_for_researchers,          null: false
      t.string :title_for_students,             null: false
      t.text :description
      t.text :survey_js_model
      t.datetime :published_at,                 null: true, index: true
      t.datetime :hidden_at,                    null: true, index: true

      t.timestamps                              null: false
    end

    create_table :research_surveys do |t|
      t.references :research_survey_plan,       null: false,
                                                foreign_key: { on_update: :cascade, on_delete: :cascade },
                                                index: true
      t.references :course_membership_student,  null: false,
                                                foreign_key: { on_update: :cascade, on_delete: :cascade },
                                                index: { name: :research_surveys_on_student }
      t.jsonb :survey_js_response
      t.datetime :completed_at,                 null: true, index: true
      t.datetime :hidden_at,                    null: true, index: true

      t.timestamps                              null: false
    end

    add_index :research_surveys, [:course_membership_student_id, :research_survey_plan_id], unique: true,
              name: :research_surveys_on_student_and_plan

  end
end
