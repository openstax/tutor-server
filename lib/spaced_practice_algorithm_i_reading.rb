class SpacedPracticeAlgorithmIReading
  ## k_ago_map is an array of two-element arrays.  Each two-element
  ## array has the form [k_ago, num_k_ago_exercises].  For example:
  ##   k_ago_map: [[1,2], [5,2]]
  def initialize(k_ago_map: [])
    @k_ago_map = k_ago_map
  end

  def call(event:, task:, current_time: Time.now)
    #puts "=== SPA INVOKED ==="

    return if task.taskings.none?
    taskee_role = task.taskings.first.role

    #puts "event:       #{event}"
    #puts "task:        #{task.inspect}"
    #puts "taskee_role: #{taskee_role.inspect}"
    #puts "@k_ago_map:  #{@k_ago_map.inspect}"

    return if (event == :task_step_completion) && !task.core_task_steps_completed?

    #puts "core tasks completed"

    placeholder_task_steps = task.spaced_practice_task_steps.select{|ts| ts.placeholder?}
    return if placeholder_task_steps.none?

    #puts "placeholder steps detected"

    #puts "=== POPULATING SPEs ==="

    ireading_event_history =
      if event == :task_step_completion
        get_completion_history(taskee: taskee_role, current_task: task, current_time: current_time)
      else
        get_force_history(taskee: taskee_role, current_task: task, current_time: current_time)
      end

    maps = create_spaced_practice_exercise_pool_maps(tasks: ireading_event_history)

    #puts "map data:"
    maps.each_with_index do |map, ii|
      #puts "  content_exercises: #{maps[ii][:content_exercises].collect{|ex| ex.id}.sort}"
      #puts "  taskee_exercises:  #{maps[ii][:taskee_exercises].collect{|ex| ex.id}.sort}"
    end
    all_taskee_exercises = maps.collect{|map| map[:taskee_exercises]}.flatten.compact.uniq
    #puts "all_taskee_exercises: #{all_taskee_exercises.collect{|ex| ex.id}.sort}"

    @k_ago_map.each do |k_ago, num_k_ago_ex|
      break if k_ago >= maps.count

      k_ago_task_title = maps[k_ago][:task].title
      k_ago_task_los   = maps[k_ago][:los]

      candidate_exercises = (maps[k_ago][:content_exercises] - all_taskee_exercises).sort_by{|ex| ex.id}.take(10)
      #puts "candidate_exercises: #{candidate_exercises.collect{|ex| ex.id}.sort}"

      num_k_ago_ex.times do |index|
        task_step = placeholder_task_steps.shift
        break if task_step.nil?

        chosen_exercise = candidate_exercises.sample
        candidate_exercises.delete(chosen_exercise)
        all_taskee_exercises.push(chosen_exercise)

        #puts "  chosen_exercise:      #{chosen_exercise.inspect}"
        #puts "  candidate_exercises:  #{candidate_exercises.collect{|ex| ex.id}.sort}"
        #puts "  all_taskee_exercises: #{all_taskee_exercises.collect{|ex| ex.id}.sort}"

        exercise = OpenStax::Exercises::V1::Exercise.new(chosen_exercise.content)

        task_step.tasked.destroy!
        tasked_exercise = Tasks::Models::TaskedExercise.new(
          task_step: task_step,
          title:     exercise.title,
          url:       exercise.url,
          content:   exercise.content,
          exercise:  chosen_exercise
        )
        task_step.tasked = tasked_exercise

        tasked_exercise.inject_debug_content(debug_content: "This exercise belongs to #{get_task_debug(task)}.")
        tasked_exercise.inject_debug_content(debug_content: "The Spaced Practice Alogirthm is using the following selection rules:")
        @k_ago_map.each do |k_ago, num_ex|
          tasked_exercise.inject_debug_content(debug_content: "  choose #{num_ex} #{'exercise'.pluralize(num_ex)} from #{k_ago} iReadings ago")
        end
        tasked_exercise.inject_debug_content(debug_content: "This is the #{(index+1).ordinalize} of #{num_k_ago_ex} #{'exercise'.pluralize(num_k_ago_ex)} for k_ago=#{k_ago}")
        tasked_exercise.inject_debug_content(debug_content: "based on the following iReading history:")
        ireading_event_history.each_with_index do |task, k_ago|
          tasked_exercise.inject_debug_content(
            debug_content: "  k_ago=#{k_ago}: #{get_task_debug(task)} (CC?=#{!!task.core_task_steps_completed?}, PD=?#{!!task.past_due?})"
          )
        end
        tasked_exercise.inject_debug_content(debug_content: "and comes from a pool built from the following LOs:")
        k_ago_task_los.each do |lo|
          tasked_exercise.inject_debug_content(debug_content: "  #{lo}")
        end
        tasked_exercise.save!
        task_step.save!
      end

      break if placeholder_task_steps.count == 0
    end

    placeholder_task_steps.each do |task_step|
      #puts "filling placeholder with fake exercise"
      exercise_hash = OpenStax::Exercises::V1.fake_client.new_exercise_hash
      exercise = OpenStax::Exercises::V1::Exercise.new(exercise_hash.to_json)

      task_step.tasked.destroy!
      tasked_exercise = Tasks::Models::TaskedExercise.new(
        task_step: task_step,
        title:     exercise.title,
        url:       exercise.url,
        content:   exercise.content
      )
      tasked_exercise.inject_debug_content(debug_content: "This exercise belongs to #{get_task_debug(task)}.")
      tasked_exercise.inject_debug_content(debug_content: "The Spaced Practice Alogirthm is using the following selection rules:")
      @k_ago_map.each do |k_ago, num_ex|
        tasked_exercise.inject_debug_content(debug_content: "  choose #{num_ex} #{'exercise'.pluralize(num_ex)} from #{k_ago} iReadings ago")
      end

      tasked_exercise.inject_debug_content(debug_content: "Based on the following iReading history:")
      ireading_event_history.each_with_index do |task, k_ago|
        tasked_exercise.inject_debug_content(
          debug_content: "  k_ago=#{k_ago}: #{get_task_debug(task)} (CC?=#{!!task.core_task_steps_completed?}, PD=?#{!!task.past_due?})"
        )
      end
      tasked_exercise.inject_debug_content(debug_content: "the Spaced Practice Algorithm could not fill this exercise slot.")
      tasked_exercise.inject_debug_content(debug_content: "Eventually this slot will either go away or be filled by")
      tasked_exercise.inject_debug_content(debug_content: "a personalized exercise chosen by BigLean.")
      task_step.tasked.save!
      task_step.save!
    end
  end

  protected

  def get_task_debug(task)
    match_data = %r{\A(?<title_part>.*?):.+\z}.match(task.title)
    task_debug = if match_data
        match_data[:title_part]
      else
        task.title
      end
    task_debug
  end

  def get_completion_history(taskee:, current_task:, current_time: Time.now)
    tasks = Tasks::Models::Task.joins{taskings}
                               .where{taskings.entity_role_id == taskee.id}

    ireading_tasks = tasks.select{|task| task.task_type == "reading"}

    history_ireading_tasks = ireading_tasks.select do |task|
      add_task_to_history = task.core_task_steps_completed? || task.past_due?(current_time: current_time)
      if add_task_to_history && !task.core_task_steps_completed?
        task.populate_spaced_practice_exercises!(event: :force, current_time: current_time)
        task.save!
      end
      add_task_to_history
    end

    sorted_tasks = history_ireading_tasks.sort_by do |task|
      times = [task.due_at]
      times << task.core_task_steps_completed_at if task.core_task_steps_completed?
      times.min
    end.reverse

    sorted_tasks
  end

  def get_force_history(taskee:, current_task:, current_time: Time.now)
    tasks = Tasks::Models::Task.joins{taskings}
                               .where{taskings.entity_role_id == taskee.id}
    ireading_tasks = tasks.select{|task| task.task_type == "reading"}

    history_ireading_tasks = ireading_tasks.select do |task|
      add_task_to_history =
        if task == current_task
          true
        elsif task.core_task_steps_completed?
          task.core_task_steps_completed_at <= current_task.due_at
        else
          task.past_due?(current_time: [current_time, current_task.due_at].min)
        end

      if add_task_to_history && (task != current_task) && !task.core_task_steps_completed?
        task.populate_spaced_practice_exercises!(event: :force, current_time: [current_time, current_task.due_at].min)
        task.save!
      end
      add_task_to_history
    end

    sorted_tasks = history_ireading_tasks.sort_by do |task|
      times = [task.due_at]
      times << task.core_task_steps_completed_at if task.core_task_steps_completed?
      times.min
    end.reverse

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
