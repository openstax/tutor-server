require 'hashie/mash'

class DemoBase

  protected

  DEFAULT_TASK_DURATION = 1.week

  #############################################################################
  #
  # HELPERS
  #
  #############################################################################


  def people
    @people ||= Hashie::Mash.load(File.dirname(__FILE__)+'/people.yml')
  end

  def user_profile_for_username(username)
    UserProfile::Models::Profile.joins(:account)
      .where(account: { username: username }).first
  end

  def get_teacher_profile(initials)
    teacher_info = people.teachers[initials]
    raise "Unable to find teacher for #{initials}" unless teacher_info
    user_profile_for_username teacher_info.username
  end

  def get_student_profile(initials)
    student_info = people.students[initials]
    raise "Unable to find student for #{initials}" unless student_info
    user_profile_for_username student_info.username
  end

  def build_tasks_profile(assignment_type:, students:, step_types:)
    profile_responses = students.map do | initials, score |
      profile = get_student_profile(initials) ||
                raise("Unable to find student for initials #{initials}")
      [initials, profile, score]
    end

    TasksProfile.new(assignment_type: assignment_type,
                      profile_responses: profile_responses,
                      step_types: step_types,
                      randomizer: randomizer)
  end

  def auto_assign_students_for_period(period)
    Hash[
      period.students.map.with_index{ |initials, i|
        score = if 0 == i%5 then 'i'
                elsif 0 == i%10 then 'ns'
                else
                  70 + rand(30)
                end
        [initials, score]
      }
    ]
  end

  def each_from_auto_assignment(content, settings)

    book_locations = content.course.ecosystems.first.pages.map(&:book_location).sample(settings.steps)
    step_types = if settings.type == 'homework'
                   (['e'] * settings.steps) + ['p']
                 else
                   1.upto(settings.steps).map.with_index{ |step, i| 0==i%3 ? 'e' : 'r' }
                 end

    1.upto(settings.generate) do | number |
      yield Hashie::Mash.new( type: settings.type,
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

  def in_parallel
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        yield
      end
    end
    @threads||=[]
    @threads.push(thread)
    thread
  end

  def wait_for_parellel_completion!
    return unless @threads
    @threads.map(&:join)
  end


  class TasksProfile
    def initialize(assignment_type:, profile_responses:, step_types:, randomizer:)

      raise ":assignment_type (#{assignment_type}) must be one of {:homework,:reading}" \
        unless [:homework,:reading].include?(assignment_type)
      raise "Must have at least one step" if step_types.length == 0

      @assignment_type = assignment_type

      @step_types = step_types
      @profiles = {}
      @randomizer = randomizer

      profile_responses.each do |initials, profile, responses|
        @profiles[profile.id] = OpenStruct.new(
          responses:  get_explicit_responses(responses),
          initials: initials
        )
      end
    end

    def [](profile_id)
      @profiles[profile_id]
    end

    private

    def get_explicit_responses(entry)

      result = case entry
      when Array
        raise "Number of explicit responses (#{entry.length}) doesn't match number of steps (#{@step_types.length}) " \
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
      when 'ns'
        @step_types.count.times.collect{nil}
      when 'i'
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

    first_name, last_name = name.split(' ')
    raise "need a full name" if last_name.nil?

    # The password will be set if stubbing is disabled
    profile ||= run(UserProfile::CreateProfile, username: username,
                                                password: password,
                                                first_name: first_name,
                                                last_name: last_name).outputs.profile

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

  def new_period_student(period:, username: nil, name: nil, password: nil)
    profile = new_user_profile(username: username, name: name, password: password)
    user = profile.user
    role = run(AddUserAsPeriodStudent, period: period, user: user).outputs.role

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
  #   #                                   role: role, exercise_source: :biglearn]

  #   # entity_task.task.task_steps.first(num_correct).each do |task_step|
  #   #   Hacks::AnswerExercise[task_step: task_step, is_correct: true]
  #   # end
  # end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.where{tasks_task_plan_type == task_plan_type}.first.assistant
  end

  def get_ecosystem(course:)
    strategy = Content::Strategies::Direct::Ecosystem.new(course.ecosystems.first)
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
      settings: { page_ids: pages.collect{|page| page.id.to_s} }
    )
  end

  def assign_homework(course:, book_locations:, num_exercises:, title:)
    ecosystem = get_ecosystem(course: course)
    book = ecosystem.books.first
    pages = lookup_pages(book: book, book_locations: book_locations)
    pools = ecosystem.homework_core_pools(pages: pages)
    exercises = pools.collect{ |pl| pl.exercises }.flatten.uniq.shuffle(random: randomizer)
    exercise_ids = exercises.take(num_exercises).collect{ |e| e.id.to_s }

    raise "No exercises to assign" if exercise_ids.blank?

    Tasks::Models::TaskPlan.new(
      title: title,
      owner: course,
      content_ecosystem_id: ecosystem.id,
      type: 'homework',
      assistant: get_assistant(course: course, task_plan_type: 'homework'),
      settings: {
        page_ids: pages.collect{|page| page.id.to_s},
        exercise_ids: exercise_ids,
        exercises_count_dynamic: rand(3)+2
      }
    )

  end

  def add_tasking_plan(task_plan:, to:, opens_at:, due_at:, message: nil)
    targets = [to].flatten
    targets.each do |target|
      task_plan.tasking_plans << Tasks::Models::TaskingPlan.new(target: target,
                                                                task_plan: task_plan,
                                                                opens_at: opens_at,
                                                                due_at: due_at)
    end
    task_plan.save!
  end

  def distribute_tasks(task_plan:)
    entity_tasks = run(DistributeTasks, task_plan).outputs.entity_tasks

    log("Assigned #{task_plan.type} #{entity_tasks.count} times")
    log("One task looks like: " + print_entity_task(entity_task: entity_tasks.first)) \
      if entity_tasks.any?

    entity_tasks
  end

  # `responses` is an array of 1 (or true), 0 (or false), or nil; nil means
  # not completed; any non-nil means completed. 1/0 (true/false) is for
  # exercise correctness
  def work_task(task:, responses:[])
    log( "Invalid number of responses for #{task.title}" +
          "(responses,task_steps) = (#{responses.count}, #{task.steps_count})\n" +
         "(task = #{print_task(task: task)}) \n" +
         "Continuing: Any tasks that do not have a response will not be worked" ) \
      if responses.count != task.steps_count

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
      Hacks::AnswerExercise.call(task_step: step, is_correct: response)
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
    CourseProfile::Models::Profile.where(name: name).first.try(:course)
  end

  def create_course(name:)
    course = run(:create_course, name: name).outputs.course
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
  end

  def print_task(task:)

    types = task.task_steps.collect do |step|
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
    codes = task.task_steps.collect{ |step| step_code(step) }
    "Task #{task.id} / #{task.task_type}\n#{codes.join(', ')}\n#{types.join(' ')}"
  end

  def print_entity_task(entity_task:)
    print_task(task: entity_task.task)
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
