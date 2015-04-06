class SpacedPracticeAlgorithmIReading
  def call(event:, task:, current_time: Time.now)
    puts "=== SPA INVOKED ==="

    return if task.taskings.none?
    taskee_role = task.taskings.first.role

    puts "event:  #{event}"
    puts "task:   #{task.inspect}"
    puts "taskee_role: #{taskee_role.inspect}"

    return unless task.core_task_steps_completed?

    puts "core tasks completed"

    placeholder_task_steps = task.spaced_practice_task_steps.select{|ts| ts.placeholder?}
    return if placeholder_task_steps.none?

    puts "placeholder steps detected"

    puts "=== POPULATING SPEs ==="

    ireading_event_history = get_ireading_task_history(taskee: taskee_role, current_time: current_time)
    maps = create_spaced_practice_exercise_pool_maps(tasks: ireading_event_history)

    puts "map data:"
    maps.each_with_index do |map, ii|
      puts "  content_exercises: #{maps[ii][:content_exercises].collect{|ex| ex.id}.sort}"
      puts "  taskee_exercises:  #{maps[ii][:taskee_exercises].collect{|ex| ex.id}.sort}"
    end

    candidate_exercises = (maps[0][:content_exercises] - maps[0][:taskee_exercises]).sort_by{|ex| ex.id}.take(10)
    puts "candidate_exercises: #{candidate_exercises.collect{|ex| ex.id}.sort}"

    placeholder_task_steps.each do |task_step|
      chosen_exercise = candidate_exercises.sample
      candidate_exercises.delete(chosen_exercise)

      puts "  chosen_exercise:     #{chosen_exercise.inspect}"
      puts "  candidate_exercises: #{candidate_exercises.collect{|ex| ex.id}.sort}"

      exercise = OpenStax::Exercises::V1::Exercise.new(chosen_exercise.content)

      task_step.tasked.destroy!
      task_step.tasked = Tasks::Models::TaskedExercise.new(
        task_step: task_step,
        title:     exercise.title,
        url:       exercise.url,
        content:   exercise.content,
        exercise:  chosen_exercise
      )
      task_step.tasked.save!
      task_step.save!
    end
  end

  protected

  def get_ireading_task_history(taskee:, current_time: Time.now)
    tasks = Tasks::Models::Task.joins{taskings}
                               .where{taskings.entity_role_id == taskee.id}

    ireading_tasks = tasks.select{|task| task.task_type == "reading"}

    completed_ireading_tasks = ireading_tasks.select do |task|
      task.core_task_steps_completed? || task.past_due?(current_time: current_time)
    end

    sorted_tasks = completed_ireading_tasks.sort_by do |task|
      times = [task.due_at]
      times << task.core_task_steps_completed_at if task.core_task_steps_completed?
      times.min
    end

    sorted_tasks
  end

  def create_spaced_practice_exercise_pool_maps(tasks:)
    maps = tasks.collect do |task|
      page_ids = task.task_plan.settings['page_ids']
      content_pages = Content::Models::Page.find(page_ids)
      los = content_pages.collect do |page|
        page_los = page.page_tags.select{|page_tag| page_tag.tag.lo?}
                                 .collect{|page_tag| page_tag.tag.name}
        page_los
      end.flatten.compact.uniq

      taskee_exercises = task.spaced_practice_task_steps.collect do |task_step|
        exercise = if task_step.spaced_practice_group? && !task_step.placeholder?
          task_step.tasked.send(:exercise)
        end
        exercise
      end.flatten.compact.uniq

      content_exercises = Content::Models::Exercise.joins{exercise_tags.tag}.where{exercise_tags.tag.name.in los}.uniq

      {
        task: task,
        los: los,
        content_exercises: content_exercises,
        taskee_exercises:  taskee_exercises,
      }
    end
    maps
  end

end
