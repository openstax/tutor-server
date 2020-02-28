module Catalog
  class UpdateOffering
    lev_routine

    protected

    def exec(id, attributes, update_courses = false)
      outputs.offering = Catalog::Models::Offering.find(id)
      active_courses = outputs.offering.courses.reject(&:ended?)
      outputs.num_active_courses = active_courses.length
      outputs.num_updated_courses = 0

      old_ecosystem = outputs.offering.ecosystem
      outputs.offering.update_attributes(attributes)
      new_ecosystem = outputs.offering.ecosystem
      transfer_errors_from(outputs.offering, {type: :verbatim}, true)

      return unless update_courses

      courses_to_update = active_courses.select { |course| course.ecosystem != new_ecosystem }
      outputs.num_updated_courses = courses_to_update.length

      courses_to_update.each do |course|
        job_id = CourseContent::AddEcosystemToCourse.perform_later(
          course: course, ecosystem: new_ecosystem
        )
        job = Jobba.find(job_id)
        job.save(
          course_id: course.id,
          course_name: course.name,
          ecosystem_id: new_ecosystem.id,
          ecosystem_title: new_ecosystem.title
        )
      end
    end
  end
end
