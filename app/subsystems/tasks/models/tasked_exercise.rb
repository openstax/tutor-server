class Tasks::Models::TaskedExercise < Tutor::SubSystems::BaseModel
  acts_as_tasked

  belongs_to :exercise, subsystem: :content, inverse_of: :tasked_exercises

  validates :url, presence: true
  validates :content, presence: true
  validate :free_response_provided, on: :update
  validate :valid_answer, :no_feedback

  delegate :uid, :questions, :question_formats, :question_answers, :question_answer_ids,
           :correct_question_answers, :correct_question_answer_ids, :feedback_map,
           :content_hash_without_correctness, :tags, :los, :aplos, to: :parser

  # We depend on the parser because we do not save the parsed content
  def parser
    @parser ||= OpenStax::Exercises::V1::Exercise.new(content: content)
  end

  def handle_task_step_completion!
    SendTaskedExerciseAnswerToExchange[tasked_exercise: self]
  end

  def has_correctness?
    true
  end

  def is_correct?
    correct_answer_id == answer_id
  end

  def make_correct!
    self.free_response = '.'
    self.answer_id = correct_answer_id
    self.save!
  end

  def make_incorrect!
    self.answer_id = nil
    self.save!
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

  # The following 3 methods assume only 1 Question
  def formats
    question_formats[0]
  end

  def answer_ids
    question_answer_ids[0]
  end

  def correct_answer_id
    correct_question_answer_ids[0].first
  end

  def feedback
    feedback_map[answer_id] || ''
  end

  def is_correct?
    correct_question_answer_ids.flatten.include?(answer_id)
  end

  def can_be_recovered?
    can_be_recovered
  end

  def exercise?
    true
  end

  protected

  def free_response_provided
    errors.add(:free_response, 'is required') \
      if formats.include?('free-response') && free_response.blank?
    errors.any?
  end

  def valid_answer
    # Multiple choice answer must be listed in the exercise
    return if answer_id.blank? || answer_ids.include?(answer_id.to_s)

    errors.add(:answer_id, 'is not a valid answer id for this problem')
    false
  end

  def no_feedback
    # Cannot change the answer after feedback is available
    # Feedback is available immediately for iReadings, or at the due date for HW,
    # but waits until the step is marked as completed
    return unless task_step.try(:feedback_available?)

    errors.add(:base, 'cannot be updated after feedback becomes available')
    false
  end
end
