class SendGlobalExerciseExclusionsToBiglearn
  lev_routine active_job_enqueue_options: { queue: :biglearn }

  protected

  def exec
    CourseProfile::Models::Course.find_each do |course|
      OpenStax::Biglearn::Api.update_globally_excluded_exercises course: course
    end
  end
end
