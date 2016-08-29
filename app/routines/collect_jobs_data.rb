class CollectJobsData
  lev_routine express_output: :jobs_data

  protected

  def exec(state:)
    data = []
    jobbas = Jobba.where(state: state).to_a
    jobbas_with_course_ids = jobbas.select{ |j| j.try(:data).try(:[], "course_id") }.map(&:data)
    course_ids = jobbas_with_course_ids.map{|job_data| job_data["course_id"]}

    courses = CourseProfile::Models::Profile.where(entity_course_id: course_ids).pluck(:id, :name).to_h unless course_ids.blank?

    jobbas.each do |job|
      if job.data && job.data["course_id"]
        course_id = job.data["course_id"]
        course_name = courses[course_id] rescue ""
        data << {id: job.id, state_name: job.state.name, course_ecosystem: job.data["course_ecosystem"], course_profile_profile_name: course_name}
      end
    end

    outputs[:jobs_data] = data
  end
end
