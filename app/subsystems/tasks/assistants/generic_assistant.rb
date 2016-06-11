# The generic assistant is a base class for other assistants to inherit from
# It's not intended for direct use since it does not implement the all-important `build_tasks` method
class Tasks::Assistants::GenericAssistant

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
    @exercise_cache = {}
    reset_used_exercises
  end

  protected

  attr_reader :task_plan, :taskees

  def ecosystem
    return @ecosystem unless @ecosystem.nil?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(task_plan.ecosystem)
    @ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)
  end

  def get_all_page_exercises_with_tags(page, tags)
    sorted_tags = [tags].flatten.uniq.sort

    @exercise_cache[page.id] ||= {}
    @exercise_cache[page.id][sorted_tags] ||= ecosystem.exercises_with_tags(sorted_tags,
                                                                            pages: page)
  end

  def reset_used_exercises
    @used_exercise_numbers = Set.new
  end

  def get_random_unused_page_exercise_with_tags(page, tags)
    raise 'You must call reset_used_exercises before get_random_unused_page_exercise_with_tags' \
      if @used_exercise_numbers.nil?

    exercises = get_all_page_exercises_with_tags(page, tags)

    candidate_exercises = exercises.reject do |ex|
      @used_exercise_numbers.include?(ex.number)
    end

    candidate_exercises.sample.tap do |chosen_exercise|
      @used_exercise_numbers << chosen_exercise.number unless chosen_exercise.nil?
    end
  end

end
