class TaskedExercise < ActiveRecord::Base
  acts_as_tasked

  validates :url, presence: true
  validates :content, presence: true
  validate :valid_state, :valid_answer, :not_completed

  delegate :answers, :correct_answer_ids, :content_without_correctness,
           to: :wrapper

  def wrapper
    @wrapper ||= OpenStax::Exercises::V1::Exercise.new(content)
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
  def correct_answer_id
    correct_answer_ids.first
  end

  def answer_ids
    answers.collect do |q|
      q.collect{|a| a['id'].to_s}
    end.first
  end

  protected

  # Eventually this will be enforced by the exercise substeps
  def valid_state
    # Can't answer multiple choice before free response
    return if !free_response.blank? || answer_id.blank?

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
