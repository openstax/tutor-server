class CreateCourseMembershipPeriods < ActiveRecord::Migration
  def change
    create_table :course_membership_periods do |t|
      t.references :entity_course, null: false
      t.string :name, null: false

      t.timestamps null: false

      t.index [:entity_course_id, :name], unique: true
    end

    add_foreign_key :course_membership_periods, :entity_courses, on_update: :cascade,
                                                                 on_delete: :cascade
  end
end
