# Creates demo assignments for demo students in a demo course
class Demo::Assign < Demo::Base
  lev_routine use_jobba: true

  uses_routine DistributeTasks, as: :distribute_tasks,
                                translations: { outputs: { type: :verbatim } }

  protected

  def normalize_book_locations(book_locations)
    book_locations.first.is_a?(Array) ? book_locations : [ book_locations ]
  end

  def exec(assign:, random_seed: nil)
    srand random_seed

    course = find_course assign[:course]
    ecosystem = course.ecosystems.first

    all_book_locations = assign[:task_plans].flat_map do |task_plan|
      normalize_book_locations task_plan[:book_locations]
    end.uniq
    pages_by_book_location = ecosystem.pages.where(
      Content::Models::Page.arel_table[:book_location].in all_book_locations
    ).preload(:homework_core_pool).index_by(&:book_location)
    missing_book_locations = all_book_locations - pages_by_book_location.keys
    raise(
      "Could not find a page in #{ecosystem.title} with the following book location(s): #{
        missing_book_locations.map(&:inspect).join(', ')
      }"
    ) unless missing_book_locations.empty?

    types = assign[:task_plans].map { |task_plan| task_plan[:type] }.uniq
    assistants_by_task_plan_type = {}
    course.course_assistants.where(tasks_task_plan_type: types).preload(:assistant).each do |ca|
      assistants_by_task_plan_type[ca.tasks_task_plan_type] = ca.assistant
    end
    missing_task_plan_types = types - assistants_by_task_plan_type.keys
    raise(
      "Could not find a course assistant for task plans of the following type(s): #{
        missing_task_plan_types.join(', ')
      }"
    ) unless missing_task_plan_types.empty?

    outputs.task_plans = assign[:task_plans].map do |task_plan|
      log do
        "Creating #{task_plan[:type]} #{task_plan[:title]
        } for course #{course.name} (id: #{course.id})"
      end

      book_locations = normalize_book_locations task_plan[:book_locations]
      pages = book_locations.map { |book_location| pages_by_book_location[book_location] }

      attrs = {
        title: task_plan[:title],
        type: task_plan[:type],
        owner: course,
        content_ecosystem_id: ecosystem.id,
        assistant: assistants_by_task_plan_type[task_plan[:type]],
        settings: { page_ids: pages.map(&:id).map(&:to_s) },
        is_preview: false
      }

      if task_plan[:type] == 'homework'
        task_plan[:num_core_exercises] ||= 3
        task_plan[:exercises_count_dynamic] ||= 3

        exercise_ids = pages.map(&:homework_core_pool).flat_map(&:content_exercise_ids).uniq
        raise "Not enough exercises to assign (using #{OpenStax::Exercises::V1.server_url})" \
          if exercise_ids.size < task_plan[:num_core_exercises]

        attrs[:settings].merge!(
          exercise_ids: exercise_ids.shuffle
                                    .take(task_plan[:num_core_exercises])
                                    .map(&:to_s),
          exercises_count_dynamic: task_plan[:exercises_count_dynamic]
        )
      end

      Tasks::Models::TaskPlan.new(attrs).tap do |task_plan_model|
        task_plan[:assigned_to].each do |assigned_to|
          period = course.periods.find_by! name: assigned_to[:period][:name]

          task_plan_model.tasking_plans << Tasks::Models::TaskingPlan.new(
            target: period,
            opens_at: assigned_to[:opens_at],
            due_at: assigned_to[:due_at],
            time_zone: course.time_zone
          )

          log { "  Added tasking plan for period #{period.name}" }
        end

        task_plan_model.save!

        ShortCode::Create[task_plan_model.to_global_id.to_s]

        # Draft plans do not undergo distribution
        if task_plan[:is_draft]
          log { "  Is a draft, skipping distributing" }
        else
          log { "  Distributing tasks" }

          tasks = run(:distribute_tasks, task_plan: task_plan_model).outputs.tasks
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

          # Clear outputs from DistributeTasks so they can be GC'd
          outputs.tasks = nil
          outputs.tasking_plans = nil
        end
      end
    end

    log_status course.name
  end
end
