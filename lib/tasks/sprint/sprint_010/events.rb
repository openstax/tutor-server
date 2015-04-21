module Sprint010
  class Events
    lev_routine

    protected

    def exec
      OpenStax::BigLearn::V1.use_fake_client
      OpenStax::Exercises::V1.use_real_client

      ## Retrieve a book from CNX
      puts "===== FETCHING CNX BOOK ====="
      cnx_book = OpenStax::Cnx::V1::Book.new(id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@4.57')
      visitor = OpenStax::Cnx::V1::BookToStringVisitor.new
      cnx_book.visit(visitor: visitor)
      puts visitor.to_s

      ## Import the book (which imports the associated exercises)
      puts "===== IMPORTING BOOK ====="
      content_book = Content::ImportBook.call(cnx_book: cnx_book).outputs.book

      ## Retrieve the page info
      page_data = Content::VisitBook.call(book: content_book, visitor_names: :page_data).outputs.page_data

      page_data.each do |page_data|
        puts "id: #{page_data.id}"
        puts "  title:   #{page_data.title}"
        puts "  LOs:     #{page_data.los}"
        puts "  version: #{page_data.version}"
      end

      puts "===== CREATING ASSISTANT and ASSIGNMENT DATA ====="

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

      puts "===== CREATING USERS, COURSES, ROLES and ASSIGNMENTS ====="

      puts "--- 0 Plans ---"

      zero_plan_course          = CreateCourse[name: 'Physics - 0 Plans']

      zero_plan_student         = FactoryGirl.create :user_profile, username: 'zero_plan_student'
      zero_plan_teacher         = FactoryGirl.create :user_profile, username: 'zero_plan_teacher'
      zero_plan_teacher_student = FactoryGirl.create :user_profile, username: 'zero_plan_teacher_student'

      AddUserAsCourseStudent.call(course: zero_plan_course, user: zero_plan_student.entity_user)
      zero_plan_student_role_1 = Entity::Role.last

      AddUserAsCourseTeacher.call(course: zero_plan_course, user: zero_plan_teacher.entity_user)
      zero_plan_teacher_role_1 = Entity::Role.last

      AddUserAsCourseStudent.call(course: zero_plan_course, user: zero_plan_teacher_student.entity_user)
      zero_plan_student_role_2 = Entity::Role.last
      AddUserAsCourseTeacher.call(course: zero_plan_course, user: zero_plan_teacher_student.entity_user)
      zero_plan_teacher_role_2 = Entity::Role.last

      puts zero_plan_course.inspect
      puts zero_plan_student.inspect
      puts zero_plan_teacher.inspect
      puts zero_plan_teacher_student.inspect

      puts "--- 1 Plan ---"

      one_plan_course          = CreateCourse[name: 'Physics - 1 Plan']

      one_plan_student         = FactoryGirl.create :user_profile, username: 'one_plan_student'
      one_plan_teacher         = FactoryGirl.create :user_profile, username: 'one_plan_teacher'
      one_plan_teacher_student = FactoryGirl.create :user_profile, username: 'one_plan_teacher_student'

      AddUserAsCourseStudent.call(course: one_plan_course, user: one_plan_student.entity_user)
      one_plan_student_role_1 = Entity::Role.last

      AddUserAsCourseTeacher.call(course: one_plan_course, user: one_plan_teacher.entity_user)
      one_plan_teacher_role_1 = Entity::Role.last

      AddUserAsCourseStudent.call(course: one_plan_course, user: one_plan_teacher_student.entity_user)
      one_plan_student_role_2 = Entity::Role.last
      AddUserAsCourseTeacher.call(course: one_plan_course, user: one_plan_teacher_student.entity_user)
      one_plan_teacher_role_2 = Entity::Role.last

      puts one_plan_course.inspect
      puts one_plan_student.inspect
      puts one_plan_teacher.inspect
      puts one_plan_teacher_student.inspect

      taskee_roles = [one_plan_student_role_1, one_plan_student_role_2]
      puts "taskee_roles: #{taskee_roles.inspect}"

      ## task = reading_task_groups[assignment_index][taskee_index]
      reading_task_groups = page_data[1..1].each_with_index.collect do |page_data, ii|
        tasks = create_tasks(
          page_id:   page_data.id,
          taskees:   taskee_roles,
          assistant: assistant,
          owner:     one_plan_course,
          opens_at:  task_dates[ii][:opens_at],
          due_at:    task_dates[ii][:due_at],
          title:     "iReading #{ii+1}: #{page_data.title}"
        )
        tasks
      end

      puts "--- 4 Plan ---"

      four_plan_course          = CreateCourse[name: 'Physics - 4 Plan']

      four_plan_student         = FactoryGirl.create :user_profile, username: 'four_plan_student'
      four_plan_teacher         = FactoryGirl.create :user_profile, username: 'four_plan_teacher'
      four_plan_teacher_student = FactoryGirl.create :user_profile, username: 'four_plan_teacher_student'

      AddUserAsCourseStudent.call(course: four_plan_course, user: four_plan_student.entity_user)
      four_plan_student_role_1 = Entity::Role.last

      AddUserAsCourseTeacher.call(course: four_plan_course, user: four_plan_teacher.entity_user)
      four_plan_teacher_role_1 = Entity::Role.last

      AddUserAsCourseStudent.call(course: four_plan_course, user: four_plan_teacher_student.entity_user)
      four_plan_student_role_2 = Entity::Role.last
      AddUserAsCourseTeacher.call(course: four_plan_course, user: four_plan_teacher_student.entity_user)
      four_plan_teacher_role_2 = Entity::Role.last

      puts four_plan_course.inspect
      puts four_plan_student.inspect
      puts four_plan_teacher.inspect
      puts four_plan_teacher_student.inspect

      taskee_roles = [four_plan_student_role_1, four_plan_student_role_2]
      puts "taskee_roles: #{taskee_roles.inspect}"

      ## task = reading_task_groups[assignment_index][taskee_index]
      reading_task_groups = page_data[1..4].each_with_index.collect do |page_data, ii|
        tasks = create_tasks(
          page_id:   page_data.id,
          taskees:   taskee_roles,
          assistant: assistant,
          owner:     four_plan_course,
          opens_at:  task_dates[ii][:opens_at],
          due_at:    task_dates[ii][:due_at],
          title:     "iReading #{ii+1}: #{page_data.title}"
        )
        tasks
      end

    end

    private

    def create_tasks(page_id:, taskees:, assistant:, owner:, opens_at: Time.now, due_at: opens_at+1.week, title: 'iReading')
      ## create TaskPlans for each Page with LOs
      task_plan = FactoryGirl.create(:tasks_task_plan,
        assistant: assistant,
        owner:     owner,
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
