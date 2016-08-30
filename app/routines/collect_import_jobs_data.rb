class CollectImportJobsData
  lev_routine express_output: :import_jobs_data

  protected

  def exec(state:)
    data = []
    jobbas = Jobba.where(state: state).to_a
    jobbas_with_course_ecosystem = jobbas.select{ |j| j.try(:data).try(:[], "course_ecosystem") }
    course_ids = jobbas_with_course_ecosystem.map{|job| job.data["course_id"]}


    courses =  course_ids.blank? ? {} : CourseProfile::Models::Profile.where(entity_course_id: course_ids).pluck(:entity_course_id, :name).to_h
    jobbas_with_course_ecosystem.each do |job|
      course_id = job.data["course_id"]
      course_name = courses[course_id]
      data << {id: job.id, state_name: job.state.name, course_ecosystem: job.data["course_ecosystem"], course_profile_profile_name: course_name}
    end

    outputs[:import_jobs_data] = data
  end
end
