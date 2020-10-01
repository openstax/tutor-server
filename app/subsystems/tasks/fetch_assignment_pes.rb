class Tasks::FetchAssignmentPes
  lev_routine express_output: :exercises, transaction: :read_committed

  uses_routine FilterExcludedExercises, as: :filter_excluded_exercises
  uses_routine ChooseExercises,         as: :choose_exercises

  # Returns a number of recommended personalized exercises for the given task using Glicko ratings
  def exec(task:, current_time: Time.current)
    case task.task_type
    when 'reading', 'homework'
      pool_method = "#{task.task_type}_dynamic_exercise_ids".to_sym
    when 'chapter_practice', 'page_practice', 'mixed_practice', 'practice_worst_topics'
      pool_method = :practice_widget_exercise_ids
    else
      outputs.exercises = []
      return
    end

    num_pe_placeholders_steps_by_page_id = {}
    task.task_steps.personalized_group
                   .filter(&:placeholder?)
                   .group_by(&:content_page_id).each do |page_id, steps|
      num_pe_placeholders_steps_by_page_id[page_id] = steps.size
    end

    page_ids = task.task_steps.map(&:content_page_id).compact.uniq
    exercise_ids = Content::Models::Page.where(id: page_ids).pluck(pool_method).flatten
    exercises = Content::Models::Exercise.where(id: exercise_ids).to_a
    exercises_by_page_id = exercises.group_by(&:content_page_id)

    outputs.eligible_page_ids = page_ids.sort
    outputs.initially_eligible_exercise_uids = exercises.map(&:uid).sort
    outputs.admin_excluded_uids = []
    outputs.course_excluded_uids = []
    outputs.role_excluded_uids = []

    chosen_exercises = num_pe_placeholders_steps_by_page_id.flat_map do |page_id, count|
      ex = page_id.nil? ? exercises_by_page_id.values.flatten : exercises_by_page_id[page_id]

      filter_and_choose_exercises(
        exercises: ex,
        task: task,
        count: count,
        current_time: current_time
      )
    end

    outputs.exercises = chosen_exercises
  end

  protected

  def filter_and_choose_exercises(
    exercises:,
    task:,
    count:,
    additional_excluded_numbers: [],
    current_time: Time.current
  )
    # Assumes tasks only have 1 tasking
    role ||= task&.taskings&.first&.role

    # Always exclude all exercises already assigned to the current task
    excluded_exercise_ids = task.exercise_steps(preload_taskeds: true)
                                .map(&:tasked)
                                .map(&:content_exercise_id)

    additional_excluded_numbers += Content::Models::Exercise.where(
      id: excluded_exercise_ids
    ).pluck(:number)

    outs = run(
      :filter_excluded_exercises,
      exercises: exercises,
      task: task,
      role: role,
      additional_excluded_numbers: additional_excluded_numbers,
      current_time: current_time
    ).outputs

    outputs.admin_excluded_uids = (outputs.admin_excluded_uids + outs.admin_excluded_uids).uniq.sort
    outputs.course_excluded_uids = (
      outputs.course_excluded_uids + outs.course_excluded_uids
    ).uniq.sort
    outputs.role_excluded_uids = (
      outputs.role_excluded_uids + outs.role_excluded_uids
    ).uniq.sort

    run(
      :choose_exercises,
      exercises: outs.exercises,
      role: role,
      count: count,
      already_assigned_exercise_numbers: outs.already_assigned_exercise_numbers
    ).outputs.exercises
  end
end
