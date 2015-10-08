class SendTaskedExerciseAnswerToExchange

  lev_routine

  protected

  def exec(tasked_exercise:)
    url = tasked_exercise.url
    roles = tasked_exercise.task_step.task.taskings.collect{ |t| t.role }
    users = Role::GetUsersForRoles[roles]
    identifiers = users.collect{ |user| user.exchange_write_identifier }

    # Currently assuming no group tasks
    identifier = identifiers.first

    # "trial" is set to only "1" for now. When multiple
    # attempts are supported, it will be incremented to indicate the attempt #
    trial = 1

    # Currently assuming only one question per tasked_exercise (see also correct_answer_id)
    answer_id = tasked_exercise.answer_id

    OpenStax::Exchange.record_multiple_choice_answer(identifier, url, trial, answer_id)

    grade = tasked_exercise.is_correct? ? 1 : 0
    grader = 'tutor'

    OpenStax::Exchange.record_grade(identifier, url, trial, grade, grader)
  end

end
