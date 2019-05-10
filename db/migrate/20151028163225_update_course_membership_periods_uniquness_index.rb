class UpdateCourseMembershipPeriodsUniqunessIndex < ActiveRecord::Migration[4.2]
  def change
    reversible do |direction|
      direction.up do
        remove_index :course_membership_periods, [:entity_course_id, :name]
        add_index :course_membership_periods, [:entity_course_id, :name],
                                              unique: true,
                                              where: "deleted_at IS NULL"
      end

      direction.down do
        remove_index :course_membership_periods, [:entity_course_id, :name]
        add_index :course_membership_periods, [:entity_course_id, :name], unique: true
      end
    end
  end
end
