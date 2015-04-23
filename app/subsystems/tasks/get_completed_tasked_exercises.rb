module Tasks
  class GetCompletedTaskedExercises
    lev_routine express_output: :completed_tasked_exercises

    include VerifyAndGetIdArray

    uses_routine SearchLocalExercises,
      translations: { outputs: { map: { items: :content_exercises } } },
      as: :search_exercises

    protected
    def exec(roles:, tags:)
      run(:search_exercises, assigned_to: roles, tag: tags, match_count: 1)
      exercises = get_completed_tasked_exercises
      outputs[:completed_tasked_exercises] = exercises.collect do |te|
        {
          id: te.id,
          can_be_recovered: te.can_be_recovered,
          url: te.url,
          content: te.content,
          title: te.title,
          free_response: te.free_response,
          answer_id: te.answer_id
        }
      end
    end

    private
    def get_completed_tasked_exercises
      Models::TaskedExercise.joins(:exercise).where(exercise: {
        url: outputs.content_exercises.flatten.uniq.collect(&:url)
      }).to_a.keep_if(&:completed?)
    end
  end
end
