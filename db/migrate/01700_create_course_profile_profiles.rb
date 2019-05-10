class CreateCourseProfileProfiles < ActiveRecord::Migration[4.2]
  def change
    create_table :course_profile_profiles do |t|
      t.references :school_district_school, index: true,
                                            foreign_key: { on_update: :cascade,
                                                           on_delete: :nullify }
      t.references :entity_course, null: false,
                                   index: { unique: true },
                                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :name,   null: false
      t.string :timezone, null: false, default: 'Central Time (US & Canada)'

      t.timestamps null: false

      t.index :name
    end
  end
end
