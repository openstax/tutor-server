# Creates demo assignments for demo students in a demo course
class Demo::Assign < Demo::Base
  lev_routine transaction: :read_committed, use_jobba: true

  uses_routine DistributeTasks, as: :distribute_tasks,
                                translations: { outputs: { type: :verbatim } }

  protected

  def convert_book_locations(book_locations)
    return [] if book_locations.nil?

    case book_locations.first
    when Hash
      book_locations.map { |book_location| [ book_location[:chapter], book_location[:section] ] }
    when Array
      book_locations
    else
      [ book_locations ]
    end
  end

  def exec(assign:, random_seed: nil)
    srand random_seed

    course = assign[:course]
    course_model = find_course! course
    ecosystem = course_model.course_ecosystems.first!.ecosystem

    task_plans = course[:task_plans]
    task_plans_by_hash = find_course_task_plans course_model, task_plans

    all_book_locations = task_plans.flat_map do |task_plan|
      convert_book_locations task_plan[:book_locations]
    end.compact.uniq
    pages_by_book_location = ecosystem.pages.where(
      Content::Models::Page.arel_table[:book_location].in all_book_locations
    ).index_by(&:book_location)
    missing_book_locations = all_book_locations - pages_by_book_location.keys
    raise(
      ActiveRecord::RecordNotFound,
      "Could not find a Page in #{ecosystem.title} with the following book location(s): #{
        missing_book_locations.map(&:inspect).join(', ')
      }"
    ) unless missing_book_locations.empty?

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

      book_locations = convert_book_locations task_plan[:book_locations]
      pages = book_locations.map { |book_location| pages_by_book_location[book_location] }
      page_ids = pages.map(&:id).map(&:to_s)

      attrs = {
        title: title,
        type: type,
        owner: course_model,
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

        exercise_ids = pages.flat_map(&:homework_core_exercise_ids).uniq
        raise(
          ActiveRecord::RecordNotFound,
          "Not enough Exercises to assign (using #{OpenStax::Exercises::V1.server_url})"
        ) if exercise_ids.size < task_plan[:exercises_count_core]

        attrs[:settings].merge!(
          page_ids: page_ids,
          exercise_ids: exercise_ids.shuffle.take(task_plan[:exercises_count_core]).map(&:to_s),
          exercises_count_dynamic: task_plan[:exercises_count_dynamic]
        )
      when 'external'
        task_plan[:external_url] ||= 'https://example.com'

        attrs[:settings][:external_url] = task_plan[:external_url]
      end

      task_plan[:is_published] = true if task_plan[:is_published].nil?

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
          closes_at: assigned_to[:closes_at] || course_model.ends_at - 1.day,
          time_zone: course_model.time_zone
        )
      end

      task_plan_model.save!

      ShortCode::Create[task_plan_model.to_global_id.to_s]

      # Draft plans do not undergo distribution
      if task_plan[:is_published]
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
      else
        log { "  Is a draft, skipping distributing" }
      end

      task_plan_model
    end

    log_status course_model.name
  end
end
