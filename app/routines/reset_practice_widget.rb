class ResetPracticeWidget

  lev_routine express_output: :task

  uses_routine GetPracticeWidget, as: :get_practice_widget

  uses_routine CreatePracticeWidgetTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_practice_widget_task

  protected

  def exec(role:, page_ids: nil, chapter_ids: nil, randomize: true)
    course = role.student.try!(:course)

    if course.present?
      fatal_error(code: :course_not_started) unless course.started?
      fatal_error(code: :course_ended) if course.ended?
    end

    # Get the existing practice widget and hard-delete
    # incomplete exercises from it so they can be used in later practice
    existing_practice_task = run(:get_practice_widget, role: role).outputs.task
    existing_practice_task.task_steps.incomplete.each(&:really_destroy!) \
      unless existing_practice_task.nil?

    run(
      :create_practice_widget_task,
      role: role,
      page_ids: page_ids,
      chapter_ids: chapter_ids,
      randomize: randomize
    )
  end

end
