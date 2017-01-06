module Catalog
  class UpdateOffering
    lev_routine

    protected

    def exec(id, attributes)
      offering = Catalog::Models::Offering.find(id)
      old_ecosystem = offering.ecosystem
      offering.update_attributes(attributes)
      new_ecosystem = offering.ecosystem
      transfer_errors_from(offering, {type: :verbatim}, true)

      return if old_ecosystem == new_ecosystem

      wrapped_ecosystem = Marshal.dump(Content::Ecosystem.new(strategy: new_ecosystem.wrap))

      offering.courses.each do |course|
        job_id = CourseContent::AddEcosystemToCourse.perform_later(
          course: course, ecosystem: wrapped_ecosystem
        )
        job = Jobba.find(job_id)
        job.save(course_ecosystem: new_ecosystem.title, course_id: course.id)
      end
    end

  end
end
