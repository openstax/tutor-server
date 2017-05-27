class AddPaymentFields < ActiveRecord::Migration
  def change
    add_column :catalog_offerings, :does_cost, :boolean, default: false, null: false
    add_column :course_profile_courses, :does_cost, :boolean, default: false, null: false

    add_column :course_membership_students, :first_paid_at, :datetime
    add_column :course_membership_students, :is_paid, :boolean, default: false, null: false
    add_column :course_membership_students, :is_comped, :boolean, default: false, null: false
    add_column :course_membership_students, :payment_due_at, :datetime
  end
end
