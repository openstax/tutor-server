class DisableConceptCoachByDefault < ActiveRecord::Migration
  def up
    change_column_default :course_profile_courses, :is_concept_coach, false
    change_column_default :catalog_offerings, :is_concept_coach, false
    change_column_default :catalog_offerings, :is_tutor, true
  end

  def down
  end
end
