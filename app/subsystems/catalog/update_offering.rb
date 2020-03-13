module Catalog
  class UpdateOffering
    lev_routine

    protected

    def exec(id, attributes, update_courses = false)
      outputs.offering = Catalog::Models::Offering.find id
      active_courses = outputs.offering.courses.where(is_preview: false).reject(&:ended?)
      outputs.num_active_courses = active_courses.size

      old_ecosystem = outputs.offering.ecosystem
      outputs.offering.update_attributes attributes
      new_ecosystem = outputs.offering.ecosystem
      transfer_errors_from outputs.offering, { type: :verbatim }, true

      if update_courses
        courses_to_update = active_courses.filter { |course| course.ecosystem != new_ecosystem }
        outputs.num_updated_courses = courses_to_update.size
      else
        courses_to_update = []
        outputs.num_updated_courses = 0
      end

      # Always update all preview courses regardless of options selected and end dates
      courses_to_update += outputs.offering.courses.where(is_preview: true).filter do |course|
        course.ecosystem != new_ecosystem
      end

      courses_to_update.each do |course|
        job_id = CourseContent::AddEcosystemToCourse.perform_later(
          course: course, ecosystem: new_ecosystem
        )
        job = Jobba.find job_id
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
