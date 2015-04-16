class Exercise < Entity
  wraps Content::Models::Exercise

  exposes :url, :title, :content

  # Could simplify some of these by building question and answer wrappers
  # (POROs, not Entity subclasses, since no DB object for them)
  delegate :uid, :questions, :formats, :question_answers, :question_answer_ids,
           :correct_question_answers, :correct_question_answer_ids,
           :content_without_correctness, to: :wrapper

  def self.search(options = {})
    SearchLocalExercises[options]
  end

  def tags
    tag_models.collect{ |t| t.name }
  end

  def los
    tag_models.select{ |t| t.lo? }.collect{ |t| t.name }
  end

  def feedback_for(answer_id)
    wrapper.feedback_map[answer_id] || ''
  end

  def answer_is_correct?(answer_id)
    correct_question_answer_ids.flatten.include?(answer_id)
  end

  protected

  # To remove the dependency on the wrapper, we would have to store the parsed content
  def wrapper
    @wrapper ||= OpenStax::Exercises::V1::Exercise.new(content)
  end

  def tag_models
    repository.exercise_tags.includes(:tag).collect{ |et| et.tag }
  end
  
end
