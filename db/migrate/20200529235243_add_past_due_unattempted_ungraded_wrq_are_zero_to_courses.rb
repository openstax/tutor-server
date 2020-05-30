class AddPastDueUnattemptedUngradedWrqAreZeroToCourses < ActiveRecord::Migration[5.2]
  def change
    add_column :course_profile_courses, :past_due_unattempted_ungraded_wrq_are_zero, :boolean,
               default: true, null: false
  end
end
