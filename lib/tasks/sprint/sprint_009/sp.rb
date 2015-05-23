module Sprint009
  class Sp

    lev_routine

    protected

    def exec
      OpenStax::Biglearn::V1.use_fake_client
      OpenStax::Exercises::V1.use_real_client

      puts "===== CREATING USERS ====="
      student1 = FactoryGirl.create :user_profile, username: 'order_1_2_3_4'
      student2 = FactoryGirl.create :user_profile, username: 'order_2_1_4_3'
      student3 = FactoryGirl.create :user_profile, username: 'no_history'

      puts "===== CREATING COURSE ====="
      physics_course = CreateCourse[name: 'Physics']

      puts "===== ASSIGNING USERS TO COURSE ROLES ====="
      AddUserAsCourseStudent.call(course: physics_course, user: student1.entity_user)
      student_role1 = Entity::Role.last
      AddUserAsCourseStudent.call(course: physics_course, user: student2.entity_user)
      student_role2 = Entity::Role.last
      AddUserAsCourseStudent.call(course: physics_course, user: student3.entity_user)
      student_role3 = Entity::Role.last

      ## Retrieve a book from CNX
      puts "===== FETCHING CNX BOOK ====="
      cnx_book = OpenStax::Cnx::V1::Book.new(id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@4.57')
      visitor = OpenStax::Cnx::V1::BookToStringVisitor.new
      cnx_book.visit(visitor: visitor)
      puts visitor.to_s

      ## Import the book (which imports the associated exercises)
      puts "===== IMPORTING BOOK ====="
      content_book = Content::ImportBook.call(cnx_book: cnx_book).outputs.book
      AddBookToCourse.call(book: content_book, course: physics_course)

      ## Retrieve the page info
      page_data = Content::VisitBook.call(book: content_book, visitor_names: :page_data).outputs.page_data

      page_data.each do |page_data|
        puts "id: #{page_data.id}"
        puts "  title:   #{page_data.title}"
        puts "  LOs:     #{page_data.los}"
        puts "  version: #{page_data.version}"
      end

      puts "===== DISTRIBUTING ASSIGNMENTS ====="
      taskee_roles = [student_role1, student_role2, student_role3]
      puts "taskee_roles: #{taskee_roles.inspect}"

      ## create the assistant
      assistant = FactoryGirl.create(:tasks_assistant,
        code_class_name: 'Tasks::Assistants::IReadingAssistant'
      )

      ## assignment data
      base_time = Time.now
      task_dates = [
        {opens_at: base_time - 25.days, due_at: base_time - 15.days},
        {opens_at: base_time - 20.days, due_at: base_time - 10.days},
        {opens_at: base_time -  5.days, due_at: base_time +  5.days},
        {opens_at: base_time + 10.days, due_at: base_time + 20.days}
      ]

      ## task = reading_task_groups[assignment_index][taskee_index]
      reading_task_groups = page_data.from(1).each_with_index.collect do |page_data, ii|
        tasks = create_tasks(
          page_id:   page_data.id,
          taskees:   taskee_roles,
          assistant: assistant,
          opens_at:  task_dates[ii][:opens_at],
          due_at:    task_dates[ii][:due_at],
          title:     "iReading #{ii+1}: #{page_data.title}"
        )
        tasks
      end

      ##
      ## create taskee histories
      ##

      puts "===== CREATING USER HISTORIES ====="

      # taskee1: task completion order #1 #2 #3 #4
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

      # taskee2: task completion order #2 #1 #4 #3
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

      # taskee3: no task completion
    end

    private

    def create_tasks(page_id:, taskees:, assistant:, opens_at: Time.now, due_at: opens_at+1.week, title: 'iReading')
      ## create TaskPlans for each Page with LOs
      task_plan = FactoryGirl.create(:tasks_task_plan,
        assistant: assistant,
        opens_at:  opens_at,
        due_at:    due_at,
        title:     title,
        settings: { page_ids: [page_id] },
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
