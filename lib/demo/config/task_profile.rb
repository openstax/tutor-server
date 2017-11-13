class Demo::Config::TaskProfile
  def initialize(assignment_type:, user_responses:, randomizer:)
    raise ":assignment_type (#{assignment_type}) must be one of [:homework, :reading]" \
      unless [:homework, :reading].include?(assignment_type)

    @assignment_type = assignment_type

    @users = {}
    @randomizer = randomizer

    user_responses.each do |username, user, responses|
      @users[user.id] = OpenStruct.new(
        responses:  responses,
        username: username
      )
    end
  end

  def [](task)
    @users[task.taskings.first.role.profile.id]
  end

  def explicit_responses(task:)
    task_profile = self[task]
    responses = task_profile.responses
    task_steps = task.task_steps.to_a
    exercise_steps = task_steps.select(&:exercise?)

    result = case responses
    when Array
      raise(
        "Number of explicit responses (#{responses.size}) for student #{task_profile.username}" +
        " doesn't match number of steps (#{task_steps.size})"
      ) if responses.size != task_steps.size

      responses
    when Integer, Float
      # The goal here is to take a grade, e.g. "78" and generate an explicit
      # set of responses that gets us as close to that as possible.

      raise "Maximum grade is 100" if responses > 100

      num_exercises = exercise_steps.size
      # Avoid division by 0 - Mark all non-exercise steps as completed
      return task_steps.map { 1 } if num_exercises == 0

      points_per_exercise = 100.0/num_exercises
      num_correct = (responses/points_per_exercise).round

      exercise_correctness = num_correct.times.map { 1 } +
                             (num_exercises - num_correct).times.map { 0 }
      exercise_correctness.shuffle!(random: @randomizer)

      task_steps.map do |task_step|
        task_step.exercise? ? exercise_correctness.pop : 1 # mark all non-exercises complete
      end
    when 'ns'
      task_steps.map { nil }
    when 'i'
      responses = task_steps.map { [1, 0, nil].sample }

      # incomplete is more than not_started, so make sure we have started by setting
      # the first response to complete/correct. always make last step incomplete to
      # guarantee not complete; if only one step, :incomplete will be the same as
      # :not_started

      responses[0] = 1
      responses[responses.size - 1] = nil

      responses
    end

    ## Steps in readings cannot be skipped - so once the first
    ## incomplete step is reached, skip all following steps.
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
