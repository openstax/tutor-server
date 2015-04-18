class Tasks::Models::TaskedExercise < Tutor::SubSystems::BaseModel
  acts_as_tasked

  belongs_to :exercise, subsystem: :content

  validates :url, presence: true
  validates :content, presence: true
  validate :valid_state, :valid_answer, :not_completed

  delegate :los, to: :parser

  ## Blatent hack below (the identifier *should* be set to
  ## the exchange identifier in the current user's profile,
  ## but the role id is a close temporary proxy):
  OpenStax::Exchange.record_multiple_choice_answer(
    identifier, url, trial, answer_id
  )

  # We depend on the parser because we do not save the parsed content
  def parser
    @parser ||= OpenStax::Exercises::V1::Exercise.new(content)
  end

  protected

  def identifier
    task_step.task.taskings.first.role.id
  end

  def trial
    task_step.id.to_s
  end

  # The following 2 methods assume only 1 Question
  def formats
    parser.question_formats[0]
  end

  def answer_ids
    parser.question_answer_ids[0]
  end

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
