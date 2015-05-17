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
  uses_routine TaskExercise, as: :task_exercise

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
    course = run(:create_course, name: 'Physics I').outputs.course
    run(:add_book, book: book, course: course)

    # Add assistants to course so teacher can create assignments
    Tasks::Models::CourseAssistant.create!(course: course,
                                           assistant: r_assistant,
                                           tasks_task_plan_type: 'reading')
    Tasks::Models::CourseAssistant.create!(course: course,
                                           assistant: hw_assistant,
                                           tasks_task_plan_type: 'homework')

    # Add an admin user
    admin = new_profile(username: 'admin', name: 'Administrator User')
    UserProfile::MakeAdministrator[user: admin.entity_user]

    # Add teacher to course
    teacher = new_profile(username: 'teacher', name: 'Bill Nye')
    run(:add_teacher, course: course, user: teacher.entity_user)

    student_roles = []

    # Add 10 students to course
    10.times.each_with_index do |i|
      student = new_profile(username: "student#{i + 1}")
      student_roles.push(run(:add_student, course: course, user: student.entity_user).outputs.role)
    end

    course.reload

    due_date_deltas = [ -1.week, 1.day, 2.days, 1.5.weeks]

    # Create and distribute 4 readings and 4 homeworks
    4.times.each_with_index do |i|
      # Set Homework pages, open date and due date
      hw_page_ids = [Content::Models::Page.offset(i + 1).first.id.to_s]
      hw_due_date = Time.now + due_date_deltas[i]
      hw_open_date = hw_due_date - 1.week

      # Set iReading pages, open date and due date
      r_page_ids = i == 0 ? [Content::Models::Page.first.id.to_s] + hw_page_ids : hw_page_ids
      r_due_date = Time.now + due_date_deltas[i]
      r_open_date = r_due_date - 1.week

      r_tp = Tasks::Models::TaskPlan.create!(
        title: "iReading ##{i + 1} - #{'Intro and ' if i == 0}Subchapter ##{i + 1}",
        owner: course,
        type: 'reading',
        assistant: r_assistant,
        opens_at: r_open_date,
        due_at: r_due_date,
        settings: { page_ids: r_page_ids }
      )
      r_tp.tasking_plans << Tasks::Models::TaskingPlan.create!(target: course, task_plan: r_tp)
      run(:distribute, r_tp)

      page_los = run(:get_los, page_ids: hw_page_ids).outputs.los
      exercise_ids = run(:search_exercises, tag: page_los, match_count: 1)
                       .outputs.items.shuffle.take(5).collect{ |e| e.id.to_s }
      hw_tp = Tasks::Models::TaskPlan.create!(title: "Homework ##{i + 1} - Subchapter ##{i + 1}",
                                              owner: course,
                                              type: 'homework',
                                              assistant: hw_assistant,
                                              opens_at: hw_open_date,
                                              due_at: hw_due_date,
                                              settings: {
                                                page_ids: hw_page_ids,
                                                exercise_ids: exercise_ids,
                                                exercises_count_dynamic: [i + 2, 4].min
                                              })
      hw_tp.tasking_plans << Tasks::Models::TaskingPlan.create!(target: course, task_plan: hw_tp)
      run(:distribute, hw_tp)
    end

    # Add another HW before the ones above (add it here so it is later w.r.t. created_at)
    hw_tp = Tasks::Models::TaskPlan.create!(title: "Homework 0",
                                              owner: course,
                                              type: 'homework',
                                              assistant: hw_assistant,
                                              opens_at: Time.now - 3.weeks,
                                              due_at: Time.now - 2.weeks,
                                              settings: {
                                                exercise_ids: Content::Models::Exercise
                                                                .order(:created_at)
                                                                .last(3).first(2) ## the last exercise is mis-tagged
                                                                .collect{ |e| e.id.to_s },
                                                exercises_count_dynamic: 2
                                              })
    hw_tp.tasking_plans << Tasks::Models::TaskingPlan.create!(target: course, task_plan: hw_tp)
    run(:distribute, hw_tp)

    # Add some practice widgets and work them for students[0]

    make_and_work_practice_widget(role: student_roles[0],
                                  num_correct: 2,
                                  page_ids: Content::Models::Page.offset(1).first.id)

    make_and_work_practice_widget(role: student_roles[0],
                                  num_correct: 5,
                                  page_ids: Content::Models::Page.offset(2).first.id)


    # Add a fake exercise with recovery to the third reading
    # because the FE wants 2 exercises to demo "try another"/"refresh my memory"
    Tasks::Models::TaskPlan.all.order(:created_at).fifth.tasks.each do |task|
      task_step = Tasks::Models::TaskStep.new(task: task, number: 8)
      exercise = run(:search_exercises, tag: 'k12phys-ch04-ex079').outputs.items.first
      task_step.tasked = run(:task_exercise,
                             exercise: exercise,
                             task_step: task_step,
                             can_be_recovered: true).outputs.tasked_exercise
      task_step.save!
    end

    # Mark some assignments as complete and correct
    Tasks::Models::TaskPlan.all.order(:created_at).each_with_index do |tp, tpi|
      tp.tasks.each_with_index do |task, ti|
        # Make Tasks 1 and 2 complete, 3 and 4 half complete and 5, 6, 7, 8 not started
        complete_count = ((2 - tpi/2)/2.0)*task.task_steps(true).count

        core_task_steps       = task.core_task_steps
        core_task_steps_count = core_task_steps.count
        offset = 0
        core_task_steps.each_with_index do |task_step, index|
          step_index = index + offset

          # Some steps are left in their incomplete state
          next unless step_index < complete_count

          if task_step.tasked.exercise?
            # half of the completed exercises get the correct answer, the rest get incorrect
            Hacks::AnswerExercise.call(task_step: task_step, is_correct: [true, false].sample)
          else
            # Not an exercise, so just mark as completed
            run(:mark_completed, task_step: task_step)
          end
        end

        spaced_practice_task_steps       = task.spaced_practice_task_steps
        spaced_practice_task_steps_count = spaced_practice_task_steps.count
        offset = core_task_steps_count
        spaced_practice_task_steps.each_with_index do |task_step, index|
          step_index = index + offset

          # Some steps are left in their incomplete state
          next unless step_index < complete_count

          if task_step.tasked.exercise?
            # half of the completed exercises get the correct answer, the rest get incorrect
            Hacks::AnswerExercise.call(task_step: task_step, is_correct: [true, false].sample)
          else
            # Not an exercise, so just mark as completed
            run(:mark_completed, task_step: task_step)
          end
        end

        personalized_task_steps       = task.personalized_task_steps
        personalized_task_steps_count = personalized_task_steps.count
        offset = core_task_steps_count + spaced_practice_task_steps_count
        personalized_task_steps.each_with_index do |task_step, index|
          step_index = index + offset

          # Some steps are left in their incomplete state
          next unless step_index < complete_count

          if task_step.tasked.exercise?
            # half of the completed exercises get the correct answer, the rest get incorrect
            Hacks::AnswerExercise.call(task_step: task_step, is_correct: [true, false].sample)
          else
            # Not an exercise, so just mark as completed
            run(:mark_completed, task_step: task_step)
          end
        end

      end
    end
  end

  def new_profile(username:, name: nil, password: 'password')
    name ||= Faker::Name.name
    first_name, last_name = name.split(' ')
    raise "need a full name" if last_name.nil?

    # The password will be set if stubbing is disabled
    profile = run(:create_profile, username: username,
                                   password: password).outputs.profile

    # We call update_columns here so this update is not sent to OpenStax Accounts
    profile.account.update_columns(first_name: first_name, last_name: last_name, full_name: name)

    profile
  end

  def make_and_work_practice_widget(role:, num_correct:, book_part_ids: [], page_ids: [])
    entity_task = ResetPracticeWidget[book_part_ids: book_part_ids,
                                      page_ids: page_ids,
                                      role: role, condition: :local]

    entity_task.task.task_steps.first(num_correct).each do |task_step|
      Hacks::AnswerExercise[task_step: task_step, is_correct: true]
    end
  end

end
