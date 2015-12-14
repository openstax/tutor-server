class SendTaskedExerciseAnswerToExchange

  lev_routine uses: { name: Role::GetUsersForRoles, as: :get_users }

  protected

  def exec(tasked_exercise:)
    url = tasked_exercise.url
    roles = tasked_exercise.task_step.task.taskings.collect{ |t| t.role }
    users = run(:get_users, users).users
    identifiers = users.collect{ |user| user.exchange_write_identifier }

    # Currently assuming no group tasks
    identifier = identifiers.first

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
