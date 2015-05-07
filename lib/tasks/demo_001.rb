class Demo001

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

  DEFAULT_TASK_DURATION = 1.week



  # `settings` is a hash with:
  #   percent_complete
  #   percent_correct
  def work_ireading(ireading:, complete:, correct:)
    # steps = ireading.task_steps

    # exercise_steps = steps.exercises
    # other_steps = steps - exercise_steps



    # step_count = steps.size

    # exercise_count = steps.
    # ireading.task_steps.each do |step|

    # end

    #     # Make Tasks 1 and 2 complete, 3 and 4 half complete and 5, 6, 7, 8 not started
    #     complete_count = ((2 - tpi/2)/2.0)*task.task_steps.count

    #     task.task_steps.each_with_index do |ts, si|
    #       # Some steps are left in their incomplete state
    #       next unless si < complete_count

    #       if ts.tasked.exercise?
    #         # 1/3 of completed exercises are blank (and incorrect)
    #         # 1/3 of completed exercises are not blank but incorrect
    #         # The remaining 1/3 are correct
    #         r = rand(3)
    #         if r == 0
    #           run(:mark_completed, task_step: ts)
    #         else
    #           Hacks::AnswerExercise.call(task_step: ts, is_correct: r > 1)
    #         end
    #       else
    #         # Not an exercise, so just mark as completed
    #         run(:mark_completed, task_step: ts)
    #       end
    #     end
    #   end




  end

  def print_task(task:)
    types = task.task_steps.collect do |step|
      case step.tasked
      when Tasks::Models::TaskedExercise
        'e'
      when Tasks::Models::TaskedReading
        'r'
      when Tasks::Models::TaskedVideo
        'v'
      when Tasks::Models::TaskedInteractive
        'i'
      else
        'o'
      end
    end

    "Task #{task.id} / #{task.task_type} / #{types.join(' ')}"
  end

  def work_ireadings(ireading:, settings:)
    raise "not yet implemented"
  end

  def initialize_randomizer(seed)
    @randomizer = Random.new(seed)
  end

  def rand(max=nil)
    max.nil? ? @randomizer.rand : @randomizer.rand(max)
  end

  def exec(random_seed: nil)
    # By default, choose a fixed seed for repeatability and fewer surprises
    initialize_randomizer(random_seed || 1234)

    archive_url = 'https://archive-staging-tutor.cnx.org/contents/'

    course = create_course(name: 'Physics I')

    book = OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
      run(:import_book, id: 'e4c329f3-1972-4835-a203-3e8c539e4df3@2.1').outputs.book
    end

    run(:add_book, book: book, course: course)

    teacher_profile = new_user_profile(username: 'teacher', name: 'Bill Nye')
    run(:add_teacher, course: course, user: teacher_profile.entity_user)

    students = 20.times.collect do |ii|
      new_course_student(course: course, username: "student#{(ii + 1).to_s.rjust(2,'0')}")
    end

    # course.reload

    initial_date = Chronic.parse("October 14, 2015")

    assign_ireading(course: course, chapter_sections: '4.2', due_at: initial_date - 1.week).each do |ireading|
      log print_task(task: ireading)
    end

    assign_ireading(course: course, chapter_sections: '3.3', due_at: initial_date - 5.days).each do |ireading|
      log(print_task(task: ireading))
    end

    assign_ireading(course: course, chapter_sections: '3.3', due_at: initial_date - 2.days).each do |ireading|
      log(print_task(task: ireading))
    end

    assign_ireading(course: course, chapter_sections: '4.3', due_at: initial_date - 0.days).each do |ireading|
      log(print_task(task: ireading))
    end

  end

  #############################################################################
  #
  # HELPERS
  #
  #############################################################################

  def new_user_profile(username:, name: nil, password: 'password')
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

  def new_course_student(course:, username: nil, name: nil, password: nil)
    profile = new_user_profile(username: username, name: name, password: password)
    user = profile.entity_user
    role = run(:add_student, course: course, user: user).outputs.role

    {
      profile: profile,
      user: user,
      role: role,
    }
  end

  # def make_and_work_practice_widget(role:, num_correct:, book_part_ids: [],
  #                                                        page_ids: [])
  #   # entity_task = ResetPracticeWidget[book_part_ids: book_part_ids,
  #   #                                   page_ids: page_ids,
  #   #                                   role: role, condition: :local]

  #   # entity_task.task.task_steps.first(num_correct).each do |task_step|
  #   #   Hacks::AnswerExercise[task_step: task_step, is_correct: true]
  #   # end
  # end

  def hw_assistant
    @hw_assistant ||= Tasks::Models::Assistant.create!(
      name: "Homework Assistant",
      code_class_name: "Tasks::Assistants::HomeworkAssistant"
    )
  end

  def reading_assistant
    @reading_assistant ||= Tasks::Models::Assistant.create!(
      name: "iReading Assistant",
      code_class_name: "Tasks::Assistants::IReadingAssistant"
    )
  end

  def assign_ireading(course:, chapter_sections:, due_at:, opens_at:nil, duration: nil, to: nil, title: nil)
    raise "Cannot set both opens_at and duration" if opens_at.present? && duration.present?
    duration ||= DEFAULT_TASK_DURATION
    opens_at ||= due_at - duration

    book = CourseContent::GetCourseBooks[course: course].first
    pages = lookup_pages(book: book, chapter_sections: chapter_sections)

    raise "No pages to assign" if pages.blank?

    task_plan = Tasks::Models::TaskPlan.create!(
      title: title || pages.first.title,
      owner: course,
      type: 'reading',
      assistant: reading_assistant,
      opens_at: opens_at,
      due_at: due_at,
      settings: { page_ids: pages.collect{|page| page.id.to_s} }
    )

    to ||= course

    log("Assigned ireading for #{chapter_sections}, due: #{due_at}, title: #{task_plan.title}")

    task_plan.tasking_plans << Tasks::Models::TaskingPlan.create!(target: to, task_plan: task_plan)

    run(:distribute, task_plan).outputs.tasks
  end

  def lookup_pages(book:, chapter_sections:)
    chapter_sections = [chapter_sections].flatten.compact

    @page_data ||= {}
    @page_data[book.id] ||= Content::VisitBook[book: book, visitor_names: :page_data]

    @page_data[book.id].select{|pd| chapter_sections.include?(pd.chapter_section)}
  end


  def create_course(name:)
    course = run(:create_course, name: name).outputs.course

    # Add assistants to course so teacher can create assignments
    Tasks::Models::CourseAssistant.create!(course: course,
                                           assistant: reading_assistant,
                                           tasks_task_plan_type: 'reading')
    Tasks::Models::CourseAssistant.create!(course: course,
                                           assistant: hw_assistant,
                                           tasks_task_plan_type: 'homework')

    course
  end

  def log(message)
    puts "#{message}\n"
  end

end
