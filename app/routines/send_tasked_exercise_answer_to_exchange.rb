class SendTaskedExerciseAnswerToExchange

  lev_routine

  protected

  def exec(tasked_exercise:)
    # Currently assuming only one question per tasked_exercise (see also correct_answer_id)
    # Also assuming no group tasks
    identifier = tasked_exercise.identifiers.first
    url = tasked_exercise.url
    # "trial" is set to only "1" for now. When multiple
    # attempts are supported, it will be incremented to indicate the attempt #
    trial = 1
    answer_id = tasked_exercise.answer_id

    OpenStax::Exchange.record_multiple_choice_answer(identifier, url, trial, answer_id)

    grade = tasked_exercise.is_correct? ? 1 : 0
    grader = 'tutor'

    OpenStax::Exchange.record_grade(identifier, url, trial, grade, grader)
  end

end
