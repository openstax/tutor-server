class Demo001

  lev_routine

  uses_routine FetchAndImportBook, as: :import_book, translations: { outputs: { type: :verbatim } }
  uses_routine CreateCourse, as: :create_course
  uses_routine AddBookToCourse, as: :add_book
  uses_routine UserProfile::CreateProfile, as: :create_profile
  uses_routine UserProfile::MakeAdministrator, as: :make_administrator
  uses_routine AddUserAsCourseTeacher, as: :add_teacher
  uses_routine AddUserAsCourseStudent, as: :add_student
  uses_routine DistributeTasks, as: :distribute
  uses_routine Content::GetLos, as: :get_los
  uses_routine SearchLocalExercises, as: :search_exercises
  uses_routine MarkTaskStepCompleted, as: :mark_completed
  uses_routine TaskExercise, as: :task_exercise

  protected

  DEFAULT_TASK_DURATION = 1.week

  def exec(random_seed: nil, print_logs: true)

    @print_logs = print_logs

    # By default, choose a fixed seed for repeatability and fewer surprises
    @random_seed = random_seed

    exercises_url = 'https://exercises-demo2.openstax.org'
    archive_url = 'https://archive-staging-tutor.cnx.org/contents/'
    cnx_book_id = 'e4c329f3-1972-4835-a203-3e8c539e4df3@2.20'

    OpenStax::Exercises::V1.with_configuration(server_url: exercises_url) do
      OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
        run(:import_book, id: cnx_book_id)
        log("Imported book #{cnx_book_id} from #{archive_url} and #{exercises_url}.")
      end
    end

    course = create_course(name: 'Physics I')
    run(:add_book, book: outputs.book, course: course)

    admin_profile = new_user_profile(username: 'admin', name: 'Administrator User')
    run(:make_administrator, user: admin_profile.entity_user)
    log("Added an admin user #{admin_profile.account.full_name}")

    teacher_profile = new_user_profile(username: 'teacher', name: 'Bill Nye')
    run(:add_teacher, course: course, user: teacher_profile.entity_user)

    students = 20.times.collect do |ii|
      new_course_student(course: course, username: "student#{(ii + 1).to_s.rjust(2,'0')}")
    end

    log("Added #{teacher_profile.account.full_name} as a teacher and added #{students.count} students.")

    # TODO change to October date once Timecop better integrated
    # initial_date = Time.now # Chronic.parse("October 14, 2015")
    initial_date = (Time.now.midnight + 1.day) - (0.001).seconds

    log("Assignments will be due around #{initial_date}.")

    ### First Chapter 3 iReading
    #

    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r r i e r r r e v e e r i e e r r e r r r e r e e ),
      entries: [
                  98,
                  67,
                  55,
                  77,
                  88,
                  :incomplete,
                  :not_started,
                  78,
                  %w( 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ),  # explicit example, could also be `100`
                  86,
                  100,
                  82,
                  71,
                  90,
                  78,
                  87,
                  :incomplete,
                  :incomplete,
                  90,
                  85
               ]
    )

    assign_ireading(course: course,
                    chapter_sections: [[3, 0], [3, 1], [3, 2]],
                    title: 'Reading 3.0 - 3.2',
                    due_at: initial_date - 5.days).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

    ### First Chapter 3 HW
    #

    responses_list = new_responses_list(
      assignment_type: :homework,
      step_types: %w( e e e e e e e e e e e ),
      entries: [
                  90,
                  87,
                  98,
                  70,
                  88,
                  :not_started,
                  :not_started,
                  :not_started,
                  100,
                  82,
                  100,
                  86,
                  81,
                  89,
                  81,
                  93,
                  :incomplete,
                  :incomplete,
                  98,
                  68
               ]
    )

    assign_homework(course: course,
                    chapter_sections: [[3, 0], [3, 1], [3, 2]],
                    num_exercises: 10,
                    due_at: initial_date - 3.days).each_with_index do |hw, index|

      work_task(task: hw, responses: responses_list[index])

    end

    ### First Chapter 4 iReading
    #

    responses_list = new_responses_list(
      assignment_type: :reading,
      step_types: %w( r i e e ),
      entries: [
                  94,
                  88,
                  60,
                  :incomplete,
                  84,
                  :incomplete,
                  92,
                  82,
                  100,
                  81,
                  100,
                  87,
                  59,
                  82,
                  :incomplete,
                  :not_started,
                  :not_started,
                  66,
                  88,
                  89
               ]
    )

    assign_ireading(course: course,
                    chapter_sections: [[4, 0], [4, 1]],
                    title: 'Reading 4.0 - 4.1',
                    due_at: initial_date - 0.days).each_with_index do |ireading, index|

      work_task(task: ireading, responses: responses_list[index])

    end

    ### First Chapter 4 HW
    #

    responses_list = new_responses_list(
      assignment_type: :homework,
      step_types: %w( e e e e e e e e e e ),
      entries: [
                 :incomplete,
                 :incomplete,
                 95,
                 72,
                 89,
                 70,
                 96,
                 87,
                 100,
                 84,
                 100,
                 83,
                 70,
                 88,
                 83,
                 90,
                 77,
                 76,
                 91,
                 85
               ]
    )

    assign_homework(course: course,
                    chapter_sections: [[4, 0], [4, 1]],
                    num_exercises: 8,
                    due_at: initial_date - 0.days).each_with_index do |hw, index|

      work_task(task: hw, responses: responses_list[index])

    end

  end

  #############################################################################
  #
  # HELPERS
  #
  #############################################################################

  def new_responses_list(assignment_type:, step_types:, entries:)
    ResponsesList.new(assignment_type: assignment_type, step_types: step_types, entries: entries, randomizer: randomizer)
  end

  class ResponsesList
    def initialize(assignment_type:, step_types:, entries:, randomizer:)
      raise ":assignment_type (#{assignment_type}) must be one of {:homework,:reading}" \
        unless [:homework,:reading].include?(assignment_type)
      raise "Must have at least one step" if step_types.length == 0

      @assignment_type = assignment_type
      @step_types = step_types
      @list = []
      @randomizer = randomizer

      entries.each do |entry|
        @list.push(get_explicit_responses(entry))
      end
    end

    def [](index)
      @list[index]
    end

    private

    def get_explicit_responses(entry)
      result = case entry
      when Array
        raise "Number of explicit responses doesn't match number of steps" \
          if @step_types.length != entry.length
        entry
      when Integer, Float
        # The goal here is to take a grade, e.g. "78" and generate an explicit
        # set of responses that gets us as close to that as possible.

        raise "Maximum grade is 100" if entry > 100

        num_exercises = @step_types.count('e')
        points_per_exercise = 100.0/num_exercises
        num_correct = [100, (entry/points_per_exercise).round].min # just to make sure not too many

        exercise_correctness = num_correct.times.collect{1} + (num_exercises - num_correct).times.collect{0}
        exercise_correctness.shuffle!(random: @randomizer)

        @step_types.collect do |type|
          case type
          when 'e'
            exercise_correctness.pop
          else
            1 # mark all non-exercises complete
          end
        end
      when :not_started
        @step_types.count.times.collect{nil}
      when :incomplete
        responses = @step_types.count.times.collect{ [1,0,nil].sample }

        # incomplete is more than not_started, so make sure we have started by setting
        # the first response to complete/correct. always make last step incomplete to
        # guarantee not complete; if only one step, :incomplete will be the same as
        # :not_started

        responses[0] = 1
        responses[responses.count-1] = nil

        responses
      end

      ## Steps in readings cannot be skipped - so once the first
      ## skipped step is reached, skip all following steps.
      if @assignment_type == :reading
        index = result.find_index(nil)
        unless index.nil?
          nils = Array.new(result[index..-1].count) { nil }
          result[index..-1] = nils
        end
      end

      result
    end
  end

  def new_user_profile(username:, name: nil, password: nil, sign_contracts: true)
    password ||= 'password'
    name ||= @@name_pool.shift || Faker::Name.name
    first_name, last_name = name.split(' ')
    raise "need a full name" if last_name.nil?

    # The password will be set if stubbing is disabled
    profile = run(:create_profile, username: username,
                                   password: password).outputs.profile

    # We call update_columns here so this update is not sent to OpenStax Accounts
    profile.account.update_columns(first_name: first_name, last_name: last_name, full_name: name)

    if sign_contracts
      sign_contract(profile: profile, name: :general_terms_of_use)
      sign_contract(profile: profile, name: :privacy_policy)
    end

    profile
  end

  def sign_contract(profile:, name:)
    string_name = name.to_s
    return if FinePrint::Contract.where{name == string_name}.none?
    FinePrint.sign_contract(profile, string_name)
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

    distribute_tasks(task_plan: task_plan,
                     to: to || course,
                     message: "Assigned ireading for #{chapter_sections}, due: #{due_at}, title: #{task_plan.title}")
  end

  def assign_homework(course:, chapter_sections:, due_at:, opens_at: nil, duration: nil,
                      num_exercises: 5, to: nil, title: nil)

    raise "Cannot set both opens_at and duration" if opens_at.present? && duration.present?
    duration ||= DEFAULT_TASK_DURATION
    opens_at ||= due_at - duration

    book = CourseContent::GetCourseBooks[course: course].first
    pages = lookup_pages(book: book, chapter_sections: chapter_sections)

    page_los = pages.collect(&:los).uniq

    exercise_ids = run(:search_exercises, tag: page_los, match_count: 1)
                       .outputs.items
                       .shuffle(random: randomizer)
                       .take(num_exercises)
                       .collect{ |e| e.id.to_s }

    task_plan = Tasks::Models::TaskPlan.create!(
      title: title || "Homework - #{chapter_sections.join('-')}",
      owner: course,
      type: 'homework',
      assistant: hw_assistant,
      opens_at: opens_at,
      due_at: due_at,
      settings: {
        page_ids: pages.collect{|page| page.id.to_s},
        exercise_ids: exercise_ids,
        exercises_count_dynamic: rand(3)+2
      }
    )

    distribute_tasks(task_plan: task_plan, to: to || course)
  end

  def distribute_tasks(task_plan:, to:, message: nil)
    task_plan.tasking_plans << Tasks::Models::TaskingPlan.create!(target: to, task_plan: task_plan)
    tasks = run(:distribute, task_plan).outputs.tasks

    log(message || "Assigned #{task_plan.type}, '#{task_plan.title}' due at #{task_plan.due_at}; #{tasks.count} times")
    log("One task looks like: " + print_task(task: tasks.first)) if tasks.any?

    tasks
  end

  # `responses` is an array of 1 (or true), 0 (or false), or nil; nil means
  # not completed; any non-nil means completed. 1/0 (true/false) is for
  # exercise correctness
  def work_task(task:, responses:)

    raise "Invalid number of responses " +
          "(responses,task_steps) = (#{responses.count}, #{task.task_steps.count})\n" +
          "(task = #{print_task(task: task)}) " \
      if responses.count != task.task_steps.count

    core_task_steps = task.core_task_steps
    core_task_steps_count = core_task_steps.count

    core_task_steps.each_with_index do |step, index|
      work_step(step, responses[index])
    end

    spaced_practice_task_steps = task.spaced_practice_task_steps
    spaced_practice_task_steps_count = spaced_practice_task_steps.count

    spaced_practice_task_steps.each_with_index do |step, index|
      work_step(step, responses[index + core_task_steps_count])
    end

    return unless task.core_task_steps_completed?

    personalized_task_steps = task.personalized_task_steps
    personalized_task_steps_count = personalized_task_steps.count

    personalized_task_steps.each_with_index do |step, index|
      work_step(step, responses[index + core_task_steps_count + spaced_practice_task_steps_count])
    end

  end

  # Works a step with the given response; for exercise steps, response can be
  # true/false or 1/0 or '1'/'0' to represent right or wrong.  For any step, a
  # nil or 'n' means incomplete, non-nil means complete.
  def work_step(step, response)
    return if response.nil? || response == 'n'

    raise "cannot complete a TaskedPlaceholder (Task: #{print_task(task: step.task)}, Step: #{step.id})" \
      if step.tasked.placeholder?

    response = (response.zero? ? false : true) if response.is_a?(Integer)
    response = (response == '0' ? false : true) if response.is_a?(String)

    if step.tasked.exercise?
      Hacks::AnswerExercise.call(task_step: step, is_correct: response)
    else
      run(:mark_completed, task_step: step)
    end
  end

  def lookup_pages(book:, chapter_sections:)
    chapter_sections = (chapter_sections.first.is_a?(Array) ? \
                        chapter_sections : [chapter_sections]).compact

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

    log("Created a course named '#{name}'.")

    course
  end

  def log(message)
    puts "#{message}\n" if @print_logs
  end

  def print_task(task:)
    types = task.task_steps.collect do |step|
      step_code = case step.tasked
      when Tasks::Models::TaskedExercise
        "e"
      when Tasks::Models::TaskedReading
        'r'
      when Tasks::Models::TaskedVideo
        'v'
      when Tasks::Models::TaskedInteractive
        'i'
      when Tasks::Models::TaskedPlaceholder
        'p'
      else
        'o'
      end

      group_code = if step.default_group?
        'd'
      elsif step.core_group?
        'c'
      elsif step.spaced_practice_group?
        's'
      elsif step.personalized_group?
        'p'
      else
        'o'
      end

      "#{group_code}#{step.id}#{step_code}"
    end

    "Task #{task.id} / #{task.task_type} / #{types.join(' ')}"
  end

  def randomizer
    @randomizer ||= Random.new(@random_seed || 1234)
  end

  def rand(max=nil)
    max.nil? ? randomizer.rand : randomizer.rand(max)
  end

  @@name_pool = %w(
    Alden\ Pyle
    Atticus\ Finch
    Augie\ March
    Charlie\ Marlow
    Lily\ Bart
    Clyde\ Griffiths
    Florentino\ Ariza
    George\ Smiley
    Harry\ Potter
    Henry\ Chinaski
    Holly\ Golightly
    Ignatius\ Reilly
    Jean\ Brodie
    Leopold\ Bloom
    Clarissa\ Dalloway
    Molly\ Bloom
    Nathan\ Zuckerman
    Rabbit\ Angstrom
    Seymour\ Glass
    Stephen\ Dedalus
    Earlene\ Hayes
    Richmond\ Lang
    Rigoberto\ Hegmann
    Isobel\ Russel
    Myron\ Sauer
    Jared\ Fritsch
    Myriam\ Reynolds
    Bernhard\ Stark
    Isobel\ Witting
    Vernien\ Walker
    Lionel\ Hayes
    Mariah\ Buckridge
    Cleve\ Pacocha
    Fabiola\ Thiel
    Beatrice\ Batz
    Mikayla\ Hintz
    Giovanny\ Jaskolski
    Ashleigh\ Goyette
    Janelle\ Skiles
    Willie\ Herman
    Dorthy\ Pagac
    Bettie\ Hackett
    Nellie\ Effertz
    Albin\ Kirlin
    Sean\ Kuvalis
    Alyce\ Tromp
    Regan\ Buckridge
    Alene\ Macejkovic
    Kevin\ Lowe
    Helmer\ Schuppe
  )

end
