# Works demo assignments
class Demo::Work < Demo::Base
  lev_routine use_jobba: true

  uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders
  uses_routine Preview::WorkTask, as: :work_task

  protected

  def exec(work:, random_seed: nil)
    srand random_seed

    course = find_course! work[:course]

    task_plans_by_hash = find_course_task_plans! course, work[:task_plans]
    outputs.task_plans = task_plans_by_hash.values

    work[:task_plans].each do |task_plan|
      task_plan_model = task_plans_by_hash[task_plan]

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
        ActiveRecord::RecordNotFound,
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
