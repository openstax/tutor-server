class AddIsConceptCoachToCourseProfileProfiles < ActiveRecord::Migration[4.2]
  def change
    # Add is_concept_coach column, but set it to false for all existing courses
    add_column :course_profile_profiles, :is_concept_coach, :boolean, null: false, default: false

    # Remove the default value so we are forced to specify it in the future
    change_column_default :course_profile_profiles, :is_concept_coach, nil
  end
end
