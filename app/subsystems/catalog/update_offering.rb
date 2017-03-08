module Catalog
  class UpdateOffering

    lev_routine

    protected

    def exec(id, attributes, update_courses = false)
      offering_model = Catalog::Models::Offering.find(id)
      outputs.offering = Catalog::Offering.new(strategy: offering_model.wrap)
      active_courses = offering_model.courses.reject(&:ended?)
      outputs.num_active_courses = active_courses.length
      outputs.num_updated_courses = 0

      old_ecosystem = offering_model.ecosystem
      offering_model.update_attributes(attributes)
      new_ecosystem = offering_model.ecosystem
      transfer_errors_from(offering_model, {type: :verbatim}, true)

      return unless update_courses

      courses_to_update = active_courses.select do |course|
        course.ecosystems.first != new_ecosystem
      end
      outputs.num_updated_courses = courses_to_update.length

      courses_to_update.each do |course|
        job_id = CourseContent::AddEcosystemToCourse.perform_later(
          course: course, ecosystem: new_ecosystem
        )
        job = Jobba.find(job_id)
        job.save(course_ecosystem: new_ecosystem.title, course_id: course.id)
      end
    end

  end
end
