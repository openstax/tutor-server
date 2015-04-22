module Sprint010
  class Mix

    lev_routine

    protected

    def exec
      # Create global Assistants (assignment builders)
      r_assistant = FactoryGirl.create(
        :tasks_assistant,
        code_class_name: "Tasks::Assistants::IReadingAssistant"
      )
      hw_assistant = FactoryGirl.create(
        :tasks_assistant,
        code_class_name: "Tasks::Assistants::HomeworkAssistant"
      )

      # Import sample book into Tutor
      book = FetchAndImportBook.call(
               id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58'
             ).outputs.book

      # Create course and add the imported book to it
      course = CreateCourse.call.outputs.course
      AddBookToCourse.call(book: book, course: course)

      # Add assistants to course so teacher can create assignments
      FactoryGirl.create(:tasks_course_assistant,
                         course: course,
                         assistant: r_assistant,
                         tasks_task_plan_type: 'reading')
      FactoryGirl.create(:tasks_course_assistant,
                         course: course,
                         assistant: hw_assistant,
                         tasks_task_plan_type: 'homework')

      # Add teacher to course
      teacher = FactoryGirl.create :user_profile, username: 'teacher'
      AddUserAsCourseTeacher.call(course: course, user: teacher.entity_user)

      # Add 10 students to course
      10.times.each_with_index do |i|
        student = FactoryGirl.create :user_profile, username: "student_#{i}"
        AddUserAsCourseStudent.call(course: course, user: student.entity_user)
      end

      course.reload

      # Create and distribute 3 readings and 3 homeworks
      tp_1 = FactoryGirl.create :tasks_task_plan, title: 'iReading #1 - Intro and Subchapter #1',
                                                  owner: course,
                                                  type: 'reading',
                                                  assistant: r_assistant,
                                                  settings: { page_ids: [1, 2] }
      tp_1.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
                                               target: course, task_plan: tp_1)
      DistributeTasks.call(tp_1)

      tp_2 = FactoryGirl.create :tasks_task_plan, title: 'Homework #1 - Odd Exercises',
                                                  owner: course,
                                                  type: 'homework',
                                                  assistant: hw_assistant,
                                                  settings: {
        exercise_ids: [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25],
        exercises_count_dynamic: 2
      }
      tp_2.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
                                             target: course, task_plan: tp_2)
      DistributeTasks.call(tp_2)

      tp_3 = FactoryGirl.create :tasks_task_plan, title: 'iReading #2 - Subchapter #2',
                                                  owner: course,
                                                  type: 'reading',
                                                  assistant: r_assistant,
                                                  settings: { page_ids: [3] }
      tp_3.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
                                               target: course, task_plan: tp_3)
      DistributeTasks.call(tp_3)

      tp_4 = FactoryGirl.create :tasks_task_plan, title: 'Homework #2 - Even Exercises',
                                                  owner: course,
                                                  type: 'homework',
                                                  assistant: hw_assistant,
                                                  settings: {
        exercise_ids: [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24],
        exercises_count_dynamic: 3
      }
      tp_4.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
                                               target: course, task_plan: tp_4)
      DistributeTasks.call(tp_4)

      tp_5 = FactoryGirl.create :tasks_task_plan, title: 'iReading #3 - Subchapter #3',
                                                  owner: course,
                                                  type: 'reading',
                                                  assistant: r_assistant,
                                                  settings: { page_ids: [4] }
      tp_5.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
                                               target: course, task_plan: tp_5)
      DistributeTasks.call(tp_5)

      tp_6 = FactoryGirl.create :tasks_task_plan, title: 'Homework #3 - Fibonacci Exercises',
                                                  owner: course,
                                                  type: 'homework',
                                                  assistant: hw_assistant,
                                                  settings: {
        exercise_ids: [1, 2, 3, 5, 8, 13, 21, 34, 55, 89],
        exercises_count_dynamic: 4
      }
      tp_6.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
                                               target: course, task_plan: tp_6)
      DistributeTasks.call(tp_6)

      # Mark some assignments as complete and correct
      [tp_1, tp_2, tp_3, tp_4, tp_5, tp_6].each_with_index do |tp, tpi|
        tp.reload.tasks.each_with_index do |task, ti|
          # Make Tasks 1 and 2 complete, 3 and 4 incomplete and 5 and 6 not started
          complete_count = ((2 - tpi/2)/2.0)*task.task_steps.count

          task.task_steps.each_with_index do |ts, si|
            # Only mark some steps as complete
            next unless si < complete_count

            # And 3/4 of those correct
            if ts.tasked_type.demodulize == "TaskedExercise" && rand(4) < 3
              ts.tasked.answer_id = ts.tasked.correct_answer_id
              ts.tasked.free_response = Faker::Hacker.say_something_smart
              ts.tasked.save!
            end

            MarkTaskStepCompleted.call(task_step: ts)
          end
        end
      end
    end

  end
end
