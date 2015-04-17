class Tasks::Models::TaskedExercise < Tutor::SubSystems::BaseModel
  acts_as_tasked

  belongs_to :exercise, subsystem: :content

  validates :url, presence: true
  validates :content, presence: true
  validate :valid_state, :valid_answer, :not_completed

  def can_be_recovered?
    can_be_recovered
  end

  def inject_debug_content(debug_content:, pre_br: false, post_br: false)
    json_hash = JSON.parse(self.content)
    stem_html = json_hash['questions'].first['stem_html']
    match_data = %r{\<!-- debug_begin --\>\<pre\>(?<existing_debug_content>(?m:.*?))\</pre\>\<!-- debug_end --\>}.match(stem_html)
    new_debug_content = match_data ? match_data[:existing_debug_content] : ""
    new_debug_content += debug_content
    new_debug_content += "\n"
    stem_html.gsub!(%r{\<!-- debug_begin --\>(?m:.*?)\</pre\>\<!-- debug_end --\>}, '')
    stem_html += "<!-- debug_begin --><pre>#{new_debug_content}</pre><!-- debug_end -->"
    json_hash['questions'].first['stem_html'] = stem_html
    self.content = json_hash.to_json
  end

  # This is domain logic; move to a Task/TaskStep/TaskedExercise wrapper
  # submits the result to exchange
  def handle_task_step_completion!
    # Currently assuming only one question per tasked_exercise, see also correct_answer_id
    question = Exercise.new(exercise).questions.first
    # "trial" is set to only "0" for now.  When multiple
    # attempts are supported, it will be incremented to indicate the attempt #

    ## Blatent hack below (the identifier *should* be set to
    ## the exchange identifier in the current user's profile,
    ## but the role id is a close temporary proxy):
    OpenStax::Exchange.record_multiple_choice_answer(
      identifier, url, trial, answer_id
    )
  end

  protected

  def identifier
    task_step.task.taskings.first.role.id
  end

  def trial
    task_step.id.to_s
  end

  # Hack until we have substeps
  def wrapper
    @wrapper ||= OpenStax::Exercises::V1::Exercise.new(content)
  end

  def formats
    @formats ||= wrapper.question_formats.first
  end

  def answer_ids
    @answer_ids ||= wrapper.question_answer_ids.first
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
