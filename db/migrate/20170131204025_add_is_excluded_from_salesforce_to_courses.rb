class AddIsExcludedFromSalesforceToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :course_profile_courses, :is_excluded_from_salesforce, :boolean, default: false, null: false
  end
end
