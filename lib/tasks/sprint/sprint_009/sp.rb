module Sprint009
  class Sp

    lev_routine

    protected

    def exec
      OpenStax::BigLearn::V1.use_fake_client
      OpenStax::Exercises::V1.use_real_client

      ## Retrieve a book from CNX
      cnx_book = OpenStax::Cnx::V1::Book.new(id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@4.57')
      visitor = OpenStax::Cnx::V1::BookToStringVisitor.new
      cnx_book.visit(visitor: visitor)
      puts visitor.to_s

      ## Import the book (which imports the associated exercises)
      content_book = Content::ImportBook.call(cnx_book: cnx_book).outputs.book

      ## Retrieve the page info
      page_data = Content::VisitBook.call(book: content_book, visitor_names: :page_data).outputs.page_data

      page_data.each do |page_data|
        puts "id: #{page_data.id}"
        puts "  title:   #{page_data.title}"
        puts "  LOs:     #{page_data.los}"
        puts "  version: #{page_data.version}"
      end

      ## create taskees
      taskee_role1 = Entity::Role.create
      taskee_role2 = Entity::Role.create
      taskee_role3 = Entity::Role.create
      taskee_roles = [taskee_role1, taskee_role2, taskee_role3]

      ## create the assistant
      assistant = FactoryGirl.create(:tasks_assistant,
        code_class_name: 'Tasks::Assistants::IReadingAssistant'
      )

      ## assignment data
      base_time = Time.now
      task_dates = [
        {opens_at: base_time +  1.day,  due_at: base_time +  8.days},
        {opens_at: base_time +  4.days, due_at: base_time + 11.days},
        {opens_at: base_time +  7.days, due_at: base_time + 14.days},
        {opens_at: base_time + 10.days, due_at: base_time + 17.days}
      ]

      ## task = reading_task_groups[assignment_index][taskee_index]
      reading_task_groups = page_data[1..4].each_with_index.collect do |page_data, ii|
        tasks = create_tasks(
          page_id:   page_data.id,
          taskees:   taskee_roles,
          assistant: assistant,
          opens_at:  task_dates[ii][:opens_at],
          due_at:    task_dates[ii][:due_at]
        )
        tasks
      end

      ##
      ## create taskee histories
      ##

      # taskee1: in order
      reading_task_groups[0][0].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: task_dates[0][:opens_at]+(10+ii).minutes)
      end
      reading_task_groups[1][0].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: task_dates[1][:opens_at]+(10+ii).minutes)
      end
      reading_task_groups[2][0].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: task_dates[2][:opens_at]+(10+ii).minutes)
      end
      reading_task_groups[3][0].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: task_dates[3][:opens_at]+(10+ii).minutes)
      end

      # taskee2: out of order
      reading_task_groups[1][1].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: task_dates[0][:opens_at]+(10+ii).minutes)
      end
      reading_task_groups[0][1].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: task_dates[1][:opens_at]+(10+ii).minutes)
      end
      reading_task_groups[3][1].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: task_dates[2][:opens_at]+(10+ii).minutes)
      end
      reading_task_groups[2][1].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: task_dates[3][:opens_at]+(10+ii).minutes)
      end

    end

    def create_tasks(page_id:, taskees:, assistant:, opens_at: Time.now, due_at: opens_at+1.week)
      ## create TaskPlans for each Page with LOs
      task_plan = FactoryGirl.create(:tasks_task_plan,
        assistant: assistant,
        opens_at: opens_at,
        due_at:   due_at,
        settings: { page_ids: [page_id] }
      )

      ## Add TaskingPlans for each Taskee to the TaskPlans
      taskees.each do |taskee|
        task_plan.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
          task_plan: task_plan,
          target: taskee
        )
      end

      ## Create assignment tasks
      tasks = DistributeTasks.call(task_plan).outputs.tasks

      tasks
    end

  end
end
