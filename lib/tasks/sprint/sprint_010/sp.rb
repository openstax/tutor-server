module Sprint010
  class Sp

    lev_routine

    protected

    def exec
      OpenStax::BigLearn::V1.use_fake_client
      OpenStax::Exercises::V1.use_real_client

      ## Retrieve a book from CNX
      puts "===== FETCHING CNX BOOK ====="
      cnx_book = OpenStax::Cnx::V1::Book.new(id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@4.57')

      # visitor  = OpenStax::Cnx::V1::BookToStringVisitor.new
      # cnx_book.visit(visitor: visitor)
      # puts visitor.to_s

      ## Import the book (which imports the associated exercises)
      puts "===== IMPORTING BOOK ====="
      content_book = Content::ImportBook.call(cnx_book: cnx_book).outputs.book
      page_data = Content::VisitBook.call(book: content_book, visitor_names: :page_data).outputs.page_data

      page_data.each do |page_data|
        puts "id: #{page_data.id}"
        puts "  title:   #{page_data.title}"
        puts "  LOs:     #{page_data.los}"
        puts "  version: #{page_data.version}"
      end

      puts "===== CREATING COURSE ====="
      physics_course = CreateCourse[name: 'Physics']
      AddBookToCourse.call(book: content_book, course: physics_course)

      ireading_assistant = FactoryGirl.create(:tasks_assistant,
        code_class_name: 'Tasks::Assistants::IReadingAssistant'
      )

      homework_assistant = FactoryGirl.create(:tasks_assistant,
        code_class_name: 'Tasks::Assistants::HomeworkAssistant'
      )

      puts "===== CREATING TASKS ====="

      base_time = Time.now
      normal_sequence_task_dates = [
        { opens_at: base_time - 5.days, due_at: base_time + 1.days },
        { opens_at: base_time - 4.days, due_at: base_time + 2.days },
        { opens_at: base_time - 3.days, due_at: base_time + 3.days },
        { opens_at: base_time - 2.days, due_at: base_time + 4.days },
      ]

      ireading_task_info = {
        course:       physics_course,
        assistant:    ireading_assistant,
        student_name: "normal_ireading_sequence",
        dates:        normal_sequence_task_dates,
        page_infos:   page_data[1..4]
      }

      homework_task_info = {
        course:       physics_course,
        assistant:    homework_assistant,
        student_name: "normal_homework_sequence",
        dates:        normal_sequence_task_dates,
        page_infos:   page_data[1..4]
      }

      create_ireading_tasks(task_info: ireading_task_info)
      create_homework_tasks(task_info: homework_task_info)
    end

    private

    def create_ireading_tasks(task_info:)
      student = FactoryGirl.create(:user_profile, username: task_info[:student_name])
      AddUserAsCourseStudent.call(course: task_info[:course], user: student.entity_user)
      student_role = Entity::Role.last

      page_info_dates_pairs = task_info[:page_infos].zip(task_info[:dates])
      tasks = page_info_dates_pairs.collect do |page_info, dates|
        ## create TaskPlan for current Page
        task_plan = FactoryGirl.create(:tasks_task_plan,
          assistant: task_info[:assistant],
          opens_at:  dates[:opens_at],
          due_at:    dates[:due_at],
          title:     page_info.title,
          settings: { page_ids: [page_info.id] },
        )

        ## Add TaskingPlans for each Taskee to the TaskPlans
        taskees = [student_role]
        taskees.each do |taskee|
          task_plan.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
            task_plan: task_plan,
            target: taskee
          )
        end

        ## Create the task
        tasks = DistributeTasks.call(task_plan).outputs.tasks
        task = tasks.first
      end

      tasks
    end

    def create_homework_tasks(task_info:)
      student = FactoryGirl.create(:user_profile, username: task_info[:student_name])
      AddUserAsCourseStudent.call(course: task_info[:course], user: student.entity_user)
      student_role = Entity::Role.last

      page_info_dates_pairs = task_info[:page_infos].zip(task_info[:dates])
      tasks = page_info_dates_pairs.collect do |page_info, dates|

        ## create TaskPlan for current Page
        task_plan = FactoryGirl.create(:tasks_task_plan,
          assistant: task_info[:assistant],
          opens_at:  dates[:opens_at],
          due_at:    dates[:due_at],
          title:     page_info.title,
          settings: {
            exercise_ids:            page_exercise_ids(page_info.id).sample(5).sort,
            exercises_count_dynamic: 3
          },
        )

        ## Add TaskingPlans for each Taskee to the TaskPlans
        taskees = [student_role]
        taskees.each do |taskee|
          task_plan.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
            task_plan: task_plan,
            target: taskee
          )
        end

        ## Create the task
        tasks = DistributeTasks.call(task_plan).outputs.tasks
        task = tasks.first
      end

      tasks
    end

    def page_exercise_ids(page_id)
      los = Content::GetLos[page_ids: page_id]
      exercises = Content::Routines::SearchExercises[tag: los, match_count: 1]
      hw_exercises = exercises.select{|ex| (ex.tags.map(&:value) & ['problem', 'concept']).any? && \
                                            ex.tags.map(&:value).include?('ost-chapter-review')}
      ids = hw_exercises.map(&:id)
      ids
    end
  end
end
