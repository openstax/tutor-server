class Tasks::PlaceholderStrategies::HomeworkPersonalized
  def initalize
  end

  def populate_placeholders(task:)
    personalized_placeholder_task_steps = task.personalized_task_steps.select{|task_step| task_step.placeholder?}
    return if personalized_placeholder_task_steps.none?

    num_placeholders = personalized_placeholder_task_steps.count

    taskee = task.taskings.first.role

    homework_los = get_homework_los(task: task)

    exercise_uids = OpenStax::BigLearn::V1.get_projection_exercises(
      role:              taskee,
      tag_search:        biglearn_condition(homework_los),
      count:             num_placeholders,
      difficulty:        0.5,
      allow_repetitions: true
    )

    chosen_exercises = SearchLocalExercises[uid: exercise_uids]
    raise "could not fill all placeholder slots (expected #{num_placeholders} exercises, got #{chosen_exercises.count})" \
      unless chosen_exercises.count == num_placeholders

    chosen_exercise_task_step_pairs = chosen_exercises.zip(personalized_placeholder_task_steps)
    chosen_exercise_task_step_pairs.each do |exercise, step|
      step.tasked.destroy!
      tasked_exercise = TaskExercise[task_step: step, exercise: exercise]
      step.personalized_group!
      # inject_debug_content!(step.tasked, "This exercise is part of the #{step.group_type}")
    end

    task.save!
    task
  end

  def get_homework_los(task:)
    urls = task.task_steps.select{|task_step| task_step.exercise?}.
                           collect{|task_step| task_step.tasked.url}.
                           uniq

    exercise_los = Content::Models::Tag.joins{exercise_tags.exercise}
                                       .where{exercise_tags.exercise.url.in urls}
                                       .select{|tag| tag.lo?}
                                       .collect{|tag| tag.value}

    pages = Content::Routines::SearchPages[tag: exercise_los, match_count: 1]
    homework_los = Content::GetLos[page_ids: pages.map(&:id)]

    homework_los
  end

  def biglearn_condition(los)
    condition = {
      _and: [
        {
          _and: [
            'ost-chapter-review',
            {
              _or: [
                'concept',
                'problem'
              ]
            }
          ]
        },
        {
          _or: los
        }
      ]
    }

    condition
  end
end
