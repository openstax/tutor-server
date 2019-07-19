# Works demo assignments
class Demo::Work < Demo::Base
  lev_routine

  uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders
  uses_routine Preview::WorkTask, as: :work_task

  protected

  def exec(work:, random_seed: nil)
    srand random_seed

    course = find_course work[:course]

    all_task_plan_ids = work[:task_plans].map { |task_plan| task_plan[:id] }.compact
    task_plans_by_id = Tasks::Models::TaskPlan.where(owner: course, id: all_task_plan_ids)
                                              .index_by(&:id)
    missing_task_plan_ids = all_task_plan_ids - task_plans_by_id.keys
    raise(
      "Could not find a task plan in #{course.name} with the following id(s): #{
        missing_task_plan_ids.join(', ')
      }"
    ) unless missing_task_plan_ids.empty?

    all_task_plan_titles = work[:task_plans].map { |task_plan| task_plan[:title] }.compact
    task_plans_by_title = {}
    Tasks::Models::TaskPlan.where(owner: course, title: all_task_plan_titles)
                           .group_by(&:title)
                           .each do |title, task_plans|
      task_plans_by_title[title] = task_plans.max_by(&:created_at)
    end
    missing_task_plan_titles = all_task_plan_titles - task_plans_by_title.keys
    raise(
      "Could not find a task plan in #{course.name} with the following title(s): #{
        missing_task_plan_titles.join(', ')
      }"
    ) unless missing_task_plan_titles.empty?

    work[:task_plans].each do |task_plan|
      task_plan_model = if task_plan[:id].blank?
        raise(ArgumentError, 'You must provide a task plan id or title') if task_plan[:title].blank?

        task_plans_by_title[task_plan[:title]]
      else
        task_plans_by_id[task_plan[:id]]
      end

      usernames = task_plan[:tasks].map { |task| task[:student][:username] }.uniq

      # This code assumes each task has only 1 tasking
      tasks_by_username = task_plan_model.tasks
        .joins(taskings: { role: { profile: :account } })
        .where(taskings: { role: { profile: { account: { username: usernames } } } })
        .preload(
          :time_zone, taskings: { role: { profile: :account } }, task_steps: [ :tasked, :task ]
        )
        .index_by { |task| task.taskings.first.role.username }
      missing_usernames = usernames - tasks_by_username.keys
      raise(
        "Could not find tasks for the following username(s): #{missing_usernames.join(', ')}"
      ) unless missing_usernames.empty?

      log do
        "Working #{task_plan_model.type} #{task_plan_model.title
        } for course #{course.name} (id: #{course.id})"
      end

      task_plan[:tasks].each do |task|
        task_model = tasks_by_username[task[:student][:username]]
        task[:lateness] ||= -300
        current_time = task_model.due_at + task[:lateness]
        timecop_method = task[:lateness] == 0 ? :freeze : :travel

        Timecop.public_send(timecop_method, current_time) do
          # Populate placeholders steps ahead of time (with force: true) so we can
          # correctly calculate the number of complete and incomplete steps
          # Set background to true so we wait longer for Biglearn to be ready
          task_model = run(
            :populate_placeholders, task: task_model, force: true, background: true
          ).outputs.task

          num_complete_steps = (task_model.steps_count * task[:progress]).round
          completeness = [ true  ] * num_complete_steps +
                         [ false ] * (task_model.steps_count - num_complete_steps)
          completeness.shuffle! unless task_model.reading?
          score = task[:score]

          is_completed  = ->(task_step, index)             { completeness[index] }
          is_correct    = ->(task_step, index)             { rand < score }
          free_response = ->(task_step, index, is_correct) do
            parser = task_step.tasked.parser
            cqa = parser.correct_question_answers.first
            chosen_answer = (is_correct ? cqa : parser.question_answers.first - cqa).sample
            chosen_answer.nil? ? nil : chosen_answer['content_html']
          end

          run(
            :work_task,
            task: task_model,
            is_completed: is_completed,
            is_correct: is_correct,
            free_response: free_response
          )
        end
      end
    end

    log_status work[:course][:name]
  end
end
