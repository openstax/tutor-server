# The generic assistant is a base class for other assistants to inherit from
# It's not intended for direct use since it does not implement the all-important `build_tasks` method
class Tasks::Assistants::GenericAssistant

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
    @tag_exercises = {}
    reset_used_exercises
  end

  def updated_attributes_for(tasking_plan:)
    task_plan = tasking_plan.task_plan
    {
      title: task_plan.title,
      description: task_plan.description,
      opens_at: tasking_plan.opens_at,
      due_at: tasking_plan.due_at,
      feedback_at: Time.now
    }
  end

  protected

  attr_reader :task_plan, :taskees

  def ecosystem
    return @ecosystem unless @ecosystem.nil?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(task_plan.ecosystem)
    @ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)
  end

  def get_all_exercises_with_tags(tags)
    sorted_tags = tags.uniq.sort

    @tag_exercises[sorted_tags] ||= ecosystem.exercises_with_tags(sorted_tags)
  end

  def reset_used_exercises
    @used_exercise_numbers = Set.new
  end

  def get_random_unused_exercise_with_tags(tags)
    raise 'You must call reset_used_exercises before calling get_random_unused_exercise_with_tags' \
      if @used_exercise_numbers.nil?

    tag_exercises = get_all_exercises_with_tags(tags)

    candidate_exercises = tag_exercises.reject do |ex|
      @used_exercise_numbers.include?(ex.number)
    end

    candidate_exercises.sample.tap do |chosen_exercise|
      @used_exercise_numbers << chosen_exercise.number unless chosen_exercise.nil?
    end
  end

end
