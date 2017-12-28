class AddSalesforceFieldsToCourse < ActiveRecord::Migration
  def change
    add_column :course_profile_courses, :creator_campaign_member_id, :string, default: nil, null: true
    add_column :course_profile_courses, :latest_adoption_decision, :string, default: nil, null: true
  end
end
