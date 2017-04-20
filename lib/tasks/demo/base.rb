require 'hashie/mash'

require 'fork_with_connection'
require_relative 'content_configuration'

class Demo::Base

  protected

  DEFAULT_TASK_DURATION = 1.week

  #############################################################################
  #
  # HELPERS
  #
  #############################################################################


  def people
    @people ||= Hashie::Mash.load(File.join(File.dirname(__FILE__), 'config/people.yml'))
  end

  def user_for_username(username)
    User::User.find_by_username(username)
  end

  def get_teacher_user(initials)
    teacher_info = people.teachers[initials]
    raise "Unable to find teacher for #{initials}" unless teacher_info
    user_for_username teacher_info.username
  end

  def get_student_user(initials)
    student_info = people.students[initials]
    raise "Unable to find student for #{initials}" unless student_info
    user_for_username student_info.username
  end

  def build_tasks_profile(assignment_type:, students:, step_types:)
    user_responses = students.map do | initials, score |
      user = get_student_user(initials) ||
               raise("Unable to find student for initials #{initials}")
      [initials, user, score]
    end

    TasksProfile.new(assignment_type: assignment_type,
                     user_responses: user_responses,
                     step_types: step_types,
                     randomizer: randomizer)
  end

  def auto_assign_students_for_period(period)
    Hash[
      (period.students || []).map.with_index{ |initials, i|
        score = if 0 == i%5 then 'i'
                elsif 0 == i%10 then 'ns'
                else
                  70 + rand(30)
                end
        [initials, score]
      }
    ]
  end

  def get_auto_assignments(content)

    content.auto_assign.map do | settings |
      if settings.type == 'concept_coach'
        book_locations = nil
        step_types = nil
      else
        book_locations = content.course.ecosystems.first.pages.map(&:book_location)
                                                              .sample(settings.steps)
        step_types = if settings.type == 'homework'
                       (['e'] * settings.steps) + ['p']
                     else
                       1.upto(settings.steps).map.with_index{ |step, i| 0==i%3 ? 'e' : 'r' }
                     end
      end

      1.upto(settings.generate).map do | number |
        Hashie::Mash.new( type: settings.type,
                          title: "#{settings.type.titleize} #{number}",
                          num_exercises: settings.steps,
                          step_types: step_types,
                          book_locations: book_locations,
                          periods: content.periods.map do | period |
                            {
                              id: period.id,
                              opens_at: (number + 3).days.ago,
                              due_at:  (number).days.ago,
                              students: auto_assign_students_for_period(period)
                            }
                          end
                        )
      end
    end

  end

  # Lev override to prevent automatic transactions while still allowing other routines to be called
  def self.disable_automatic_lev_transactions
    define_method(:transaction_run_by?) do |who|
      return false if who == self
      super
    end
  end

  def find_or_create_catalog_offering( content, ecosystem )
    Catalog::GetOffering[ salesforce_book_name: content.salesforce_book_name ] ||
      Catalog::CreateOffering[
        salesforce_book_name: content.salesforce_book_name,
        appearance_code: content.appearance_code,
        title: content.course_name,
        description: content.course_name,
        webview_url: (content.webview_url_base ||
                      content.archive_url_base.sub(/archive\./,'')) + content.cnx_book,
        pdf_url: content.archive_url_base.sub(%r{contents/$}, 'exports/') +
                 content.cnx_book + '.pdf',
        is_concept_coach: content.is_concept_coach,
        is_tutor: !content.is_concept_coach,
        is_available: true,
        content_ecosystem_id: ecosystem.id
      ]
  end

  # Runs the given code in parallel processes
  # Calling process must not be in a transaction
  # Args should be Enumerables and will be passed to the given block in properly-sized slices
  # You will still have to iterate through the yielded values
  # The index for the first element in the original array is also passed in as the last argument
  # Returns the PID's for the spawned processes
  def in_parallel(*args, max_processes: nil, transaction: false)
    arg_size = args.first.size
    raise 'Arguments must have the same size' unless args.all?{ |arg| arg.size == arg_size }

    # This is merely the maximum number of processes spawned for each call to this method
    max_processes ||= Integer(ENV['DEMO_MAX_PROCESSES']) rescue 1

    if arg_size == 0 || max_processes < 1
      #log("Processes: 0 (inline processing) - Slice size: #{arg_size}")

      return yield *[args + [0]]
    end

    Rails.application.eager_load!

    # Use max_processes unless too few args given
    num_processes = [arg_size, max_processes].min

    # Calculate slice_size
    slice_size = (arg_size/num_processes.to_f).ceil

    # Adjust number of processes again if some process would receive an empty array
    num_processes = (arg_size/slice_size.to_f).ceil

    sliced_args = args.map{ |arg| arg.each_slice(slice_size) }
    process_args = 0.upto(num_processes - 1).map do |process_index|
      sliced_args.map{ |sliced_arg| sliced_arg.next } + [process_index*slice_size]
    end


    child_processes = 0.upto(num_processes - 1).map do |process_index|
      Tutor.fork_with_connection do
        if transaction
          ActiveRecord::Base.transaction do
            yield *process_args[process_index]
          end
        else
          yield *process_args[process_index]
        end
      end
    end

    @processes ||= []
    @processes += child_processes
  end

  # Waits for all child processes to finish
  # Returns the PID/Status pairs for the processes we had to wait on
  def wait_for_parallel_completion
    return [] if @processes.nil?

    #log('Waiting for child processes to exit...')

    results = @processes.map{ |pid| Process.wait2(pid) }

    @processes = []

    results.each do |result|
      #log("PID: #{result.first} - Status: #{result.last.exitstatus}")
      nonfatal_error(code: :process_failed) unless result.last.success?
    end

    #log('All child processes done')

    results
  end

  # Same as wait_for_parallel_completion,
  # but raises an exception if any of the child processes failed
  def wait_for_parallel_completion!
    results = wait_for_parallel_completion

    raise('Child process failed') if results.any?{ |result| !result.last.success? }
  end

  class TasksProfile
    def initialize(assignment_type:, user_responses:, step_types:, randomizer:)

      raise ":assignment_type (#{assignment_type}) must be one of [:homework, :reading]" \
        unless [:homework, :reading].include?(assignment_type)

      @assignment_type = assignment_type

      @step_types = step_types
      @users = {}
      @randomizer = randomizer

      user_responses.each do |initials, user, responses|
        @users[user.id] = OpenStruct.new(
          responses:  responses,
          initials: initials
        )
      end
    end

    def [](task)
      @users[task.taskings.first.role.profile.id]
    end

    def explicit_responses(task:)
      actual_step_types = task.task_steps.map do |task_step|
        task_step.tasked_type.demodulize.sub('Tasked', '').first.downcase
      end

      Rails.logger.warn do
        "Steps in config (#{@step_types}) don't match actual steps (#{actual_step_types})"
      end if !@step_types.nil? && @step_types != actual_step_types

      responses = self[task].responses

      result = case responses
      when Array
        raise("Number of explicit responses (#{responses.length
              }) doesn't match number of steps (#{actual_step_types.length})") \
          if actual_step_types.length != responses.length
        responses
      when Integer, Float
        # The goal here is to take a grade, e.g. "78" and generate an explicit
        # set of responses that gets us as close to that as possible.

        raise "Maximum grade is 100" if responses > 100

        num_exercises = actual_step_types.count('e')
        # Avoid division by 0 - Mark all non-exercise steps as completed
        return actual_step_types.map{ 1 } if num_exercises == 0

        points_per_exercise = 100.0/num_exercises
        num_correct = (responses/points_per_exercise).round

        exercise_correctness = num_correct.times.map{1} +
                               (num_exercises - num_correct).times.map{0}
        exercise_correctness.shuffle!(random: @randomizer)

        actual_step_types.map do |type|
          case type
          when 'e'
            exercise_correctness.pop
          else
            1 # mark all non-exercises complete
          end
        end
      when 'ns'
        actual_step_types.count.times.map{nil}
      when 'i'
        responses = actual_step_types.count.times.map{ [1,0,nil].sample }

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

  def new_user(username:, name: nil, password: nil, sign_contracts: true, faculty_status: nil)
    password ||= Rails.application.secrets.demo_user_password

    first_name, last_name = name.split(' ')
    raise "need a full name" if last_name.nil?

    # The password will be set if stubbing is disabled
    user ||= run(User::CreateUser, username: username,
                                   password: password,
                                   first_name: first_name,
                                   last_name: last_name,
                                   faculty_status: faculty_status).outputs.user

    if sign_contracts
      sign_contract(user: user, name: :general_terms_of_use)
      sign_contract(user: user, name: :privacy_policy)
    end

    user
  end

  def sign_contract(user:, name:)
    string_name = name.to_s
    return if FinePrint::Contract.where{name == string_name}.none?
    FinePrint.sign_contract(user.to_model, string_name)
  end

  def new_period_student(period:, username: nil, name: nil, password: nil)
    user = new_user(username: username, name: name, password: password)
    role = run(AddUserAsPeriodStudent, period: period, user: user).outputs.role

    {
      user: user,
      role: role,
    }
  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.where{tasks_task_plan_type == task_plan_type}.first.assistant
  end

  def get_ecosystem(course:)
    ecosystem_model = course.ecosystems.first
    return if ecosystem_model.nil?

    strategy = Content::Strategies::Direct::Ecosystem.new(ecosystem_model)
    Content::Ecosystem.new(strategy: strategy)
  end

  def assign_ireading(course:, book_locations:, title:)
    ecosystem = get_ecosystem(course: course)
    book = ecosystem.books.first
    pages = lookup_pages(book: book, book_locations: book_locations)

    raise "No pages to assign" if pages.blank?

    Tasks::Models::TaskPlan.new(
      title: title,
      owner: course,
      content_ecosystem_id: ecosystem.id,
      type: 'reading',
      assistant: get_assistant(course: course, task_plan_type: 'reading'),
      settings: { page_ids: pages.map{|page| page.id.to_s } }
    )
  end

  def assign_homework(course:, book_locations:, num_exercises:, title:)
    ecosystem = get_ecosystem(course: course)
    book = ecosystem.books.first
    pages = lookup_pages(book: book, book_locations: book_locations)
    pools = ecosystem.homework_core_pools(pages: pages)
    exercises = pools.map(&:exercises).flatten.uniq.shuffle(random: randomizer)
    exercise_ids = exercises.take(num_exercises).map{ |e| e.id.to_s }

    raise "No exercises to assign (using #{OpenStax::Exercises::V1.server_url})" \
      if exercise_ids.blank?

    Tasks::Models::TaskPlan.new(
      title: title,
      owner: course,
      content_ecosystem_id: ecosystem.id,
      type: 'homework',
      assistant: get_assistant(course: course, task_plan_type: 'homework'),
      settings: {
        page_ids: pages.map{|page| page.id.to_s},
        exercise_ids: exercise_ids,
        exercises_count_dynamic: 4
      }
    )

  end

  def assign_concept_coach(course:)
    ecosystem = get_ecosystem(course: course)
    book = ecosystem.books.first
    acceptable_pages = book.pages.select{ |page| !page.concept_coach_pool.empty? }

    raise "None of the pages in the ecosystem have exercises" if acceptable_pages.empty?

    course.students.each do |student|
      user = User::User.new(strategy: student.role.profile.wrap)
      task = GetConceptCoach[user: user,
                             book_uuid: book.uuid,
                             page_uuid: acceptable_pages.sample.uuid]
    end
  end

  def add_tasking_plan(task_plan:, to:, opens_at:, due_at:, message: nil)
    targets = [to].flatten
    targets.each do |target|
      task_plan.tasking_plans << Tasks::Models::TaskingPlan.new(
        target: target,
        task_plan: task_plan,
        opens_at: opens_at,
        due_at: due_at,
        time_zone: task_plan.owner.time_zone
      )
    end
    task_plan.save!
  end

  def distribute_tasks(task_plan:)
    tasks = run(DistributeTasks, task_plan: task_plan).outputs.tasks

    log("Assigned #{task_plan.type} #{tasks.count} times")
    log("One task looks like: " + print_task(task: tasks.first)) if tasks.any?

    tasks
  end

  def work_task(tasks_profile:, task:)
    responses = tasks_profile.explicit_responses(task: task)

    core_task_steps = task.core_task_steps(preload_tasked: true)

    core_task_steps.each_with_index do |step, index|
      work_step(step, responses[index])
    end

    spaced_practice_task_steps = task.spaced_practice_task_steps(preload_tasked: true)

    spaced_practice_task_steps.each_with_index do |step, index|
      work_step(step, responses[index + core_task_steps.size])
    end

    return unless task.reload.core_task_steps_completed?

    personalized_task_steps = task.personalized_task_steps

    personalized_task_steps.each_with_index do |step, index|
      work_step(step, responses[index + core_task_steps.size + spaced_practice_task_steps.size])
    end
  end

  # Works a step with the given response; for exercise steps, response can be
  # true/false or 1/0 or '1'/'0' to represent right or wrong.  For any step, a
  # nil or 'n' means incomplete, non-nil means complete.
  def work_step(step, response)
    return if response.nil? || response == 'n'

    raise "cannot complete a TaskedPlaceholder (Task: #{
            print_task(task: step.task)}, Step: #{step.id})" if step.tasked.placeholder?

    response = (response.zero? ? false : true) if response.is_a?(Integer)
    response = (response == '0' ? false : true) if response.is_a?(String)

    if step.tasked.exercise?
      Preview::AnswerExercise.call(task_step: step, is_correct: response)
    else
      run(MarkTaskStepCompleted, task_step: step)
    end
  end

  def lookup_pages(book:, book_locations:)
    book_locations = (book_locations.first.is_a?(Array) ? \
                      book_locations : [book_locations]).compact

    book.pages.select{ |page| book_locations.include?(page.book_location) }
  end

  def find_course(name:)
    CourseProfile::Models::Course.where(name: name).first.try(:course)
  end

  def create_course(name:, term:, year:, starts_at: nil, ends_at: nil,
                    catalog_offering:, appearance_code: nil,
                    is_preview: false, is_concept_coach: nil, is_college:,
                    school: nil, time_zone: nil)
    course = run(:create_course,
                 name: name,
                 term: term,
                 year: year,
                 starts_at: starts_at,
                 ends_at: ends_at,
                 is_preview: is_preview,
                 is_concept_coach: is_concept_coach,
                 is_college: is_college,
                 catalog_offering: catalog_offering,
                 appearance_code: appearance_code,
                 school: school,
                 time_zone: time_zone).outputs.course
    log("Created a course named '#{name}'.")
    course
  end

  def find_period(course:, name:)
    Entity::Relation.new(CourseMembership::Models::Period.where(course: course, name: name)).first
  end

  def log(message)
    puts "#{message}\n" if @print_logs
  end

  def step_code(step)
    case step.tasked
    when Tasks::Models::TaskedExercise
      'e'
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
  end

  def print_task(task:)

    types = task.task_steps.map do |step|
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

      "#{group_code}#{step.id}#{step_code(step)}"
    end
    codes = task.task_steps.map{ |step| step_code(step) }
    "Task #{task.id} / #{task.task_type}\n#{codes.join(', ')}\n#{types.join(' ')}"
  end

  def randomizer
    # By default, choose a fixed seed for repeatability and fewer surprises
    @randomizer ||= Random.new(@random_seed || 1234789)
  end

  def rand(max=nil)
    max.nil? ? randomizer.rand : randomizer.rand(max)
  end

  def set_random_seed(random_seed)
    @random_seed = random_seed
  end

  def set_print_logs(print_logs)
    @print_logs = print_logs
  end

end
