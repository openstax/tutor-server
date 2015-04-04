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
      taskee1 = Entity::User.create
      taskee2 = Entity::User.create
      taskee3 = Entity::User.create
      taskees = [taskee1, taskee2, taskee3]

      ## create the assistant
      assistant = FactoryGirl.create(:tasks_assistant,
        code_class_name: 'Tasks::Assistants::IReadingAssistant'
      )

      ## create the tasks
      reading1_tasks = create_tasks(page_id: page_data[1].id, taskees: taskees, assistant: assistant)
      reading2_tasks = create_tasks(page_id: page_data[2].id, taskees: taskees, assistant: assistant)
      reading3_tasks = create_tasks(page_id: page_data[3].id, taskees: taskees, assistant: assistant)
      reading4_tasks = create_tasks(page_id: page_data[4].id, taskees: taskees, assistant: assistant)

      ## create taskee histories
      base_time = Time.now

      # taskee1: in order
      reading1_tasks[0].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: base_time + ii.minutes)
      end
      reading2_tasks[0].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: base_time + ii.minutes)
      end
      reading3_tasks[0].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: base_time + ii.minutes)
      end
      reading4_tasks[0].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: base_time + ii.minutes)
      end

      # taskee2: out of order
      reading2_tasks[1].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: base_time + ii.minutes)
      end
      reading1_tasks[1].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: base_time + ii.minutes)
      end
      reading4_tasks[1].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: base_time + ii.minutes)
      end
      reading3_tasks[1].core_task_steps.each_with_index do |task_step, ii|
        MarkTaskStepCompleted.call(task_step: task_step, completion_time: base_time + ii.minutes)
      end
    end

    def create_tasks(page_id:, taskees:, assistant:)
      ## create TaskPlans for each Page with LOs
      task_plan = FactoryGirl.create(:tasks_task_plan,
        assistant: assistant,
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
