class AddIsExcludedFromSalesforceToCourses < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :is_excluded_from_salesforce, :boolean, default: false, null: false
  end
end
