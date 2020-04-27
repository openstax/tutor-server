class FixClonedCourses < ActiveRecord::Migration[5.2]
  def up
    CourseProfile::Models::Course.preload(:course_ecosystems).find_each do |course|
      valid_ecosystem_ids = course.course_ecosystems.map(&:content_ecosystem_id)

      missing_ecosystem_ids = Tasks::Models::TaskPlan.where(owner: course).where.not(
        content_ecosystem_id: valid_ecosystem_ids
      ).distinct.pluck(:content_ecosystem_id)

      missing_ecosystem_ids.each do |ecosystem_id|
        CourseContent::Models::CourseEcosystem.create!(
          course: course, content_ecosystem_id: ecosystem_id
        )
      end
    end
  end

  def down
  end
end
