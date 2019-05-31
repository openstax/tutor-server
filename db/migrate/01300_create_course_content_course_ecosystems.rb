class CreateCourseContentCourseEcosystems < ActiveRecord::Migration[4.2]
  def change
    create_table :course_content_course_ecosystems do |t|
      t.references :entity_course, null: false,
                                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :content_ecosystem, null: false,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.timestamps null: false

      t.index [:content_ecosystem_id, :entity_course_id],
              name: 'course_ecosystems_on_ecosystem_id_course_id'
      t.index [:entity_course_id, :created_at],
              name: 'course_ecosystems_on_course_id_created_at'
    end
  end
end
