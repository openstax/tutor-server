class CreateCourseEcosystemCourseEcosystems < ActiveRecord::Migration
  def change
    create_table :course_ecosystem_course_ecosystems do |t|
      t.references :entity_course, null: false,
                                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :ecosystem_ecosystem, null: false,
                                         index: { name: 'course_ecosystems_on_ecosystem_id' },
                                         foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.timestamps null: false

      t.index [:entity_course_id, :ecosystem_ecosystem_id],
              unique: true, name: 'course_ecosystems_on_course_id_ecosystem_id_unique'
    end
  end
end
