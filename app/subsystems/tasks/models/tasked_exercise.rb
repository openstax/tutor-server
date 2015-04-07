class Tasks::Models::TaskedExercise < Tutor::SubSystems::BaseModel
  acts_as_tasked

  belongs_to :exercise, subsystem: :content
  protected :exercise

  validates :url, presence: true
  validates :content, presence: true
  validate :valid_state, :valid_answer, :not_completed

  delegate :answers, :correct_answer_ids, :content_without_correctness,
           to: :wrapper

  def wrapper
    @wrapper ||= OpenStax::Exercises::V1::Exercise.new(content)
  end

  def can_be_recovered?
    can_be_recovered
  end

  def url
    u = super
    return u unless u.nil?
    u = wrapper.url
    self.url = u
    save if persisted?
    u
  end

  def title
    t = super
    return t unless t.nil?
    t = wrapper.title
    self.title = t
    save if persisted?
    t
  end

  def feedback_html
    wrapper.feedback_html(answer_id)
  end

  # Assume only 1 question for now
  def formats
    wrapper.formats.first
  end

  def correct_answer_id
    correct_answer_ids.first
  end

  def answer_ids
    answers.collect do |q|
      q.collect{|a| a['id'].to_s}
    end.first
  end

  def inject_debug_content(debug_content:)
    json_hash = JSON.parse(self.content)
    json_hash['questions'].first['stem_html'] = debug_content + json_hash['questions'].first['stem_html']
    self.content = json_hash.to_json
  end

  # submits the result to exchange
  def handle_task_step_completion!
    # Currently assuming only one question per tasked_exercise, see also correct_answer_id
    question = wrapper.questions.first
    # "trial" is set to only "0" for now.  When multiple
    # attempts are supported, it will be incremented to indicate the attempt #
    OpenStax::Exchange.record_multiple_choice_answer(
      question['id'], url, '0', answer_id
    )
  end

  protected

  # Eventually this will be enforced by the exercise substeps
  def valid_state
    # Can't answer multiple choice before free response
    # if question formats includes 'free-response'
    return if !free_response.blank? || \
              answer_id.blank? || \
              !formats.include?('free-response')

    errors.add(:free_response,
               'must not be blank before entering a multiple choice answer')
    false
  end

  def valid_answer
    # Multiple choice answer must be listed in the exercise
    return if answer_id.blank? || answer_ids.include?(answer_id.to_s)

    errors.add(:answer_id, 'is not a valid answer id for this problem')
    false
  end

  def not_completed
    # Cannot change the answer after exercise is turned in
    return if task_step.try(:completed_at_was).blank?

    errors.add(:base, 'cannot be updated after it is marked as completed')
    false
  end
end
