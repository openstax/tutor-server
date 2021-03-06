# Creates demo assignments for demo students in a demo course
class Demo::Assign < Demo::Base
  lev_routine transaction: :read_committed, use_jobba: true

  uses_routine DistributeTasks, as: :distribute_tasks
  uses_routine FilterExcludedExercises, as: :filter_exercises

  protected

  def convert_book_indices(book_indices)
    return [] if book_indices.nil?

    case book_indices.first
    when Hash
      book_indices.map { |book_indices| [ book_indices[:chapter], book_indices[:section] ] }
    when Array
      book_indices
    else
      [ book_indices ]
    end
  end

  def exec(assign:, random_seed: nil)
    srand random_seed

    course = assign[:course]
    course_model = find_course! course
    ecosystem = course_model.course_ecosystems.first!.ecosystem

    task_plans = course[:task_plans]
    task_plans_by_hash = find_course_task_plans course_model, task_plans

    all_book_indices = task_plans.flat_map do |task_plan|
      convert_book_indices task_plan[:book_indices]
    end.compact.uniq
    pages_by_book_indices = ecosystem.pages.where(
      Content::Models::Page.arel_table[:book_indices].in all_book_indices
    ).index_by(&:book_indices)
    missing_book_indices = all_book_indices - pages_by_book_indices.keys
    raise(
      ActiveRecord::RecordNotFound,
      "Could not find a Page in #{ecosystem.title} with the following book indices: #{
        missing_book_indices.map(&:inspect).join(', ')
      }"
    ) unless missing_book_indices.empty?

    types = task_plans.map { |task_plan| task_plan[:type] }.uniq
    assistants_by_task_plan_type = {}
    course_model.course_assistants.where(tasks_task_plan_type: types)
                                  .preload(:assistant)
                                  .each do |ca|
      assistants_by_task_plan_type[ca.tasks_task_plan_type] = ca.assistant
    end
    missing_task_plan_types = types - assistants_by_task_plan_type.keys
    raise(
      ActiveRecord::RecordNotFound,
      "Could not find a Course assistant for Task plans of the following type(s): #{
        missing_task_plan_types.join(', ')
      }"
    ) unless missing_task_plan_types.empty?

    outputs.task_plans = task_plans.map do |task_plan|
      type = task_plan[:type]
      title = task_plan[:title]
      log { "Creating #{type} #{title} for course #{course_model.name} (id: #{course_model.id})" }

      book_indices = convert_book_indices task_plan[:book_indices]
      pages = book_indices.map { |book_indices| pages_by_book_indices[book_indices] }
      page_ids = pages.map(&:id).map(&:to_s)

      attrs = {
        title: title,
        type: type,
        course: course_model,
        content_ecosystem_id: ecosystem.id,
        assistant: assistants_by_task_plan_type[type],
        settings: {},
        is_preview: false,
        grading_template: course_model.grading_templates.detect { |gt| gt.task_plan_type == type }
      }

      # Type-specific task_plan settings
      case task_plan[:type]
      when 'reading'
        attrs[:settings][:page_ids] = page_ids
      when 'homework'
        task_plan[:exercises_count_core] ||= 3
        task_plan[:exercises_count_dynamic] ||= 3

        exercises = task_plan[:exercises]
        exercises_setting = if exercises.nil?
          exercise_ids = pages.flat_map(&:homework_core_exercise_ids).uniq
          raise(
            ActiveRecord::RecordNotFound,
            "Not enough Exercises to assign (using #{OpenStax::Exercises::V1.server_url})"
          ) if exercise_ids.size < task_plan[:exercises_count_core]

          ex_models = Content::Models::Exercise.select(
            :id, :user_profile_id, :number, :version, :number_of_questions, :deleted_at
          ).where(id: exercise_ids).to_a
          ex = run(:filter_exercises, exercises: ex_models, course: course_model).outputs.exercises
          ex.shuffle.take(task_plan[:exercises_count_core]).map do |exercise|
            { id: exercise.id.to_s, points: [ 1 ] * exercise.number_of_questions }
          end
        else
          numbers = exercises.map { |ex| ex[:number] }
          ex_ids_by_numbers = ecosystem.exercises.where(number: numbers).pluck(:number, :id).to_h
          exercises.map do |exercise|
            { id: ex_ids_by_numbers[exercise[:number]].to_s, points: exercise[:points] }
          end
        end

        attrs[:settings].merge!(
          page_ids: page_ids,
          exercises: exercises_setting,
          exercises_count_dynamic: task_plan[:exercises_count_dynamic]
        )
      when 'external'
        task_plan[:external_url] ||= 'https://example.com'

        attrs[:settings][:external_url] = task_plan[:external_url]
      end

      task_plan[:is_published] = true if task_plan[:is_published].nil?
      task_plan[:dropped_questions] ||= []

      task_plan_model = task_plans_by_hash[task_plan]

      if task_plan_model.nil?
        task_plan_model = Tasks::Models::TaskPlan.new attrs
      else
        task_plan_model.update_attributes attrs

        task_plan_model.tasking_plans.delete_all :delete_all
      end

      task_plan_model.tasking_plans = task_plan[:assigned_to].map do |assigned_to|
        period = course_model.periods.to_a.find do |period|
          period.name == assigned_to[:period][:name]
        end

        log { "  Added tasking plan for period #{period.name}" }

        Tasks::Models::TaskingPlan.new(
          target: period,
          opens_at: assigned_to[:opens_at],
          due_at: assigned_to[:due_at],
          closes_at: assigned_to[:closes_at] || course_model.ends_at - 1.day
        )
      end

      task_plan_model.save!

      ShortCode::Create[task_plan_model.to_global_id.to_s]

      # Draft plans do not undergo distribution
      if task_plan[:is_published]
        log { "  Distributing tasks" }

        tasks = run(:distribute_tasks, task_plan: task_plan_model).outputs.tasks
        task_plan_model.tasks.reset
        log { "Assigned #{task_plan_model.type} #{tasks.count} times" }

        log do
          task = tasks.first
          steps = task.task_steps.map do |step|
            "  #{step.number}. #{
              (
                step.group_type.split('_')[0..-2] +
                step.tasked_type.demodulize.tableize.split('_')[1..-1]
              ).map(&:first).map(&:upcase).join
            }"
          end

          "One task looks like: Task #{task.id}: #{task.task_type}\n#{steps.join("\n")}"
        end if tasks.any?

        longest_task = nil
        task_plan_model.dropped_questions = task_plan[:dropped_questions].map do |dropped_question|
          question_index = dropped_question[:question_index]
          longest_task ||= tasks.max_by(&:actual_and_placeholder_exercise_count)
          tasked_exercise = longest_task.tasked_exercises[question_index] unless question_index.nil?
          tasked_exercise ||= longest_task.tasked_exercises.sample
          Tasks::Models::DroppedQuestion.new(
            question_id: tasked_exercise.question_id, drop_method: dropped_question[:drop_method]
          )
        end

        num_dropped_questions = task_plan_model.dropped_questions.size
        if num_dropped_questions > 0
          task_plan_model.save!
          run :distribute_tasks, task_plan: task_plan_model
          task_plan_model.dropped_questions.reset
          log { "Dropped #{num_dropped_questions} questions" }
        end
      else
        log { "  Is a draft, skipping distributing" }
      end

      task_plan_model
    end

    log_status course_model.name
  end
end
