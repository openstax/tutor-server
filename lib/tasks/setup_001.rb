class Setup001

  lev_routine

  uses_routine FetchAndImportBook, as: :import_book
  uses_routine CreateCourse, as: :create_course
  uses_routine AddBookToCourse, as: :add_book
  uses_routine UserProfile::CreateProfile, as: :create_profile
  uses_routine AddUserAsCourseTeacher, as: :add_teacher
  uses_routine AddUserAsCourseStudent, as: :add_student
  uses_routine DistributeTasks, as: :distribute
  uses_routine Content::GetLos, as: :get_los
  uses_routine SearchLocalExercises, as: :search_exercises
  uses_routine MarkTaskStepCompleted, as: :mark_completed

  protected

  def exec
    # Create global Assistants (assignment builders)
    r_assistant = Tasks::Models::Assistant.create!(
      name: "iReading Assistant",
      code_class_name: "Tasks::Assistants::IReadingAssistant"
    )
    hw_assistant = Tasks::Models::Assistant.create!(
      name: "Homework Assistant",
      code_class_name: "Tasks::Assistants::HomeworkAssistant"
    )

    # Import sample book into Tutor
    book = run(:import_book, id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58').outputs.book

    # Create course and add the imported book to it
    course = run(:create_course).outputs.course
    run(:add_book, book: book, course: course)

    # Add assistants to course so teacher can create assignments
    Tasks::Models::CourseAssistant.create!(course: course,
                                           assistant: r_assistant,
                                           tasks_task_plan_type: 'reading')
    Tasks::Models::CourseAssistant.create!(course: course,
                                           assistant: hw_assistant,
                                           tasks_task_plan_type: 'homework')

    # Add teacher to course
    teacher = run(:create_profile, attrs: {username: 'teacher',
                                           password: 'password'}).outputs.profile
    run(:add_teacher, course: course, user: teacher.entity_user)

    # Add 10 students to course
    10.times.each_with_index do |i|
      student = run(:create_profile, attrs: {username: "student#{i + 1}",
                                             password: 'password'}).outputs.profile
      run(:add_student, course: course, user: student.entity_user)
    end

    course.reload

    # Create and distribute 4 readings and 4 homeworks
    4.times.each_with_index do |i|
      hw_page_ids = [Content::Models::Page.offset(i + 1).first.id]
      r_page_ids = i == 0 ? [Content::Models::Page.first.id] + hw_page_ids : hw_page_ids
      r_tp = Tasks::Models::TaskPlan.create!(
        title: "iReading ##{i + 1} - #{'Intro and ' if i == 0}Subchapter ##{i + 1}",
        owner: course,
        type: 'reading',
        assistant: r_assistant,
        opens_at: Time.now,
        settings: { page_ids: r_page_ids }
      )
      r_tp.tasking_plans << Tasks::Models::TaskingPlan.create!(target: course, task_plan: r_tp)
      run(:distribute, r_tp)

      page_los = run(:get_los, page_ids: hw_page_ids).outputs.los
      exercise_ids = run(:search_exercises, tag: page_los, match_count: 1).outputs.items
                                                                          .shuffle.take(5)
                                                                          .collect{ |e| e.id }
      hw_tp = Tasks::Models::TaskPlan.create!(title: "Homework ##{i + 1} - Subchapter ##{i + 1}",
                                              owner: course,
                                              type: 'homework',
                                              assistant: hw_assistant,
                                              opens_at: Time.now,
                                              settings: {
                                                page_ids: hw_page_ids,
                                                exercise_ids: exercise_ids,
                                                exercises_count_dynamic: [i + 2, 4].min
                                              })
      hw_tp.tasking_plans << Tasks::Models::TaskingPlan.create!(target: course, task_plan: hw_tp)
      run(:distribute, hw_tp)
    end

    # Mark some assignments as complete and correct
    Tasks::Models::TaskPlan.all.order(:created_at).each_with_index do |tp, tpi|
      tp.reload.tasks.each_with_index do |task, ti|
        # Make Tasks 1 and 2 complete, 3 and 4 incomplete and 5, 6, 7, 8 not started
        complete_count = ((2 - tpi/2)/2.0)*task.task_steps.count

        task.task_steps.each_with_index do |ts, si|
          # Only mark some steps as complete
          next unless si < complete_count

          # And 3/4 of those correct
          if ts.tasked_type.ends_with?("TaskedExercise") && rand(4) < 3
            ts.tasked.answer_id = ts.tasked.correct_answer_id
            ts.tasked.free_response = 'A sentence explaining all the things!'
            ts.tasked.save!
          end

          # The other 1/4 are blank and thus incorrect
          run(:mark_completed, task_step: ts)
        end
      end
    end
  end

end
