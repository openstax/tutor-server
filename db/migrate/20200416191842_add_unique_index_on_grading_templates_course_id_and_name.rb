class AddUniqueIndexOnGradingTemplatesCourseIdAndName < ActiveRecord::Migration[5.2]
  def change
    add_index :tasks_grading_templates, [ :course_profile_course_id, :name ],
              unique: true, name: 'index_tasks_grading_templates_on_course_and_name'
  end
end
