class CreateCourseMembershipPeriods < ActiveRecord::Migration[4.2]
  def change
    create_table :course_membership_periods do |t|
      t.references :entity_course, null: false, foreign_key: { on_update: :cascade,
                                                               on_delete: :cascade }
      t.string :name, null: false

      t.timestamps null: false

      t.index [:entity_course_id, :name], unique: true
    end
  end
end
