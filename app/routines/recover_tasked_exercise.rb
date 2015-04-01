# Move to whatever subsystem handles the user doing homework (iReadings)

class RecoverTaskedExercise

  lev_routine

  protected

  def exec(tasked_exercise:)
    fatal_error(code: :recovery_not_available) \
      unless tasked_exercise.has_recovery?

    pp_tag = Content::Models::Tag.find_by(name: 'practice-problem')
    lo = tasked_exercise.wrapper.los.shuffle.first
    recovery_exercise = pp_tag.exercise_tags
                              .preload(exercise: {exercise_tags: :tag})
                              .joins(exercise: {exercise_tags: :tag})
                              .where(exercise: {
                                       exercise_tags: {
                                         tag: { name: lo }
                                       }
                                    })
                              .order_by_rand.first.exercise
    outputs[:recovery_exercise] = recovery_exercise

    task_step = tasked_exercise.task_step
    task = task_step.task
    outputs[:task] = task

    recovery_step = Tasks::Models::TaskStep.new(
      task: task, number: task_step.number + 1
    )
    recovery_step.tasked = Tasks::Models::TaskedExercise.new(
      task_step: recovery_step,
      url: recovery_exercise.url,
      title: recovery_exercise.title,
      content: recovery_exercise.content
    )
    task.task_steps << recovery_step
    recovery_step.save!
    transfer_errors_from(recovery_step, type: :verbatim)

    tasked_exercise.update_attribute(:has_recovery, false)
    outputs[:recovery_step] = recovery_step
  end
end
