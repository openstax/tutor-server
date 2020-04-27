class FixClonedCourses < ActiveRecord::Migration[5.2]
  def up
    CourseProfile::Models::Course.preload(:course_ecosystems).find_each do |course|
      existing_course_ecosystems = course.course_ecosystems.to_a
      valid_ecosystem_ids = existing_course_ecosystems.map(&:content_ecosystem_id)

      missing_ecosystem_ids = Tasks::Models::TaskPlan.where(owner: course).where.not(
        content_ecosystem_id: valid_ecosystem_ids
      ).distinct.pluck(:content_ecosystem_id).sort

      next if missing_ecosystem_ids.empty?

      missing_ecosystem_ids.each do |ecosystem_id|
        CourseContent::Models::CourseEcosystem.create!(
          course: course, content_ecosystem_id: ecosystem_id
        )
      end

      # Ensure the ecosystem order is preserved
      existing_course_ecosystems.each do |course_ecosystem|
        course_ecosystem.update_attribute :created_at, Time.current
      end
    end
  end

  def down
  end
end
