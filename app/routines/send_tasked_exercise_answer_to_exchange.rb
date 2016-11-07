class SendTaskedExerciseAnswerToExchange

  lev_routine

  protected

  def exec(tasked_exercise:)
    # Currently assuming no group tasks
    role = tasked_exercise.task_step.task.taskings.first.role

    # Don't send trial course info to Exchange
    return if role.student.try!(:course).try!(:is_trial)

    identifier = role.exchange_write_identifier

    url = tasked_exercise.url

    # "trial" is currently set to the id of the task_step being answered
    trial = tasked_exercise.task_step.id.to_s

    # Currently assuming only one question per tasked_exercise (see also correct_answer_id)
    answer_id = tasked_exercise.answer_id

    OpenStax::Exchange.record_multiple_choice_answer(identifier, url, trial, answer_id)

    grade = tasked_exercise.is_correct? ? 1 : 0

    grader = 'tutor'

    OpenStax::Exchange.record_grade(identifier, url, trial, grade, grader)
  end

end
