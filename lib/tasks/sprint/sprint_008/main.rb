module Sprint008
  class Main

    lev_routine

    protected

    def exec

      # Create users

      teacher             = FactoryGirl.create :user, username: 'teacher'
      student             = FactoryGirl.create :user, username: 'student'
      teacher_and_student = FactoryGirl.create(:user, username: 'teacher_and_student')

      # Make 2 courses

      course1 = Domain::CreateCourse[name: 'Physics']
      course2 = Domain::CreateCourse[name: 'Fundamentals of Risk']

      # Import the sample content book and add it to a course

      book = Domain::FetchAndImportBook[id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58']
      Domain::AddBookToCourse[book: book, course: course1]

      # Add the teachers to their courses

      Domain::AddUserAsCourseTeacher[course: course1, user: teacher.entity_user]
      Domain::AddUserAsCourseTeacher[course: course2, user: teacher_and_student.entity_user]

      # Add the students to the courses

      Domain::AddUserAsCourseStudent[course: course1, user: student.entity_user]
      student_role = Entity::Models::Role.last
      Domain::AddUserAsCourseStudent[course: course2, user: teacher_and_student.entity_user]

      # Set up three reading tasks (will include try another)

      a = FactoryGirl.create :tasks_assistant, code_class_name: "Tasks::Assistants::IReadingAssistant"
      tp = FactoryGirl.create :tasks_task_plan, assistant: a,
                                          owner: course1,
                                          settings: { page_ids: [1, 2] }
      tp.tasking_plans << FactoryGirl.create(:tasks_tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)
      tp = FactoryGirl.create :tasks_task_plan, assistant: a,
                                          owner: course1,
                                          settings: { page_ids: [3] }
      tp.tasking_plans << FactoryGirl.create(:tasks_tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)
      tp = FactoryGirl.create :tasks_task_plan, assistant: a,
                                          owner: course1,
                                          settings: { page_ids: [4] }
      tp.tasking_plans << FactoryGirl.create(:tasks_tasking_plan, target: student,
                                                            task_plan: tp)
      DistributeTasks.call(tp)

      # Set up a practice widget
      Domain::ResetPracticeWidget.call(role: student_role, condition: :fake)

      # Set up a task plan that will have activity for the stats
      stats_tp = FactoryGirl.create :tasks_task_plan, assistant: a,
                                          owner: course1,
                                          settings: { page_ids: [1,2,3] }

      0.upto(30).each do |i|
        user = FactoryGirl.create :user, username: "student_#{i}"
        stats_tp.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,target: user, task_plan: stats_tp)
      end
      DistributeTasks.call(stats_tp)
      # mark some steps as complete and correct
      stats_tp.reload.tasks.each_with_index{ |task,index|
        task.task_steps.each{ |ts|
          next unless 0==index%2 # only mark 1/2 complete
          if ts.tasked_type == "Tasks::Models::TaskedExercise" && 1 != rand(0..4) # and 3/4 of those correct
            ts.tasked.answer_id = ts.tasked.correct_answer_id
            ts.tasked.free_response = Faker::Company.bs
            ts.tasked.save!
          end
          MarkTaskStepCompleted.call(task_step: ts) }
      }

      # Outputs

      outputs[:teacher] = teacher
      outputs[:student] = student
      outputs[:teacher_and_student] = teacher_and_student
      outputs[:course1] = course1
      outputs[:course2] = course2
      outputs[:stats_task_plan] = stats_tp
    end

  end
end
