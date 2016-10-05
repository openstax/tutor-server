class Tasks::Models::TaskedExercise < Tutor::SubSystems::BaseModel

  acts_as_tasked

  auto_uuid

  belongs_to :exercise, subsystem: :content, inverse_of: :tasked_exercises

  before_validation :set_correct_answer_id, on: :create

  validates :url, presence: true
  validates :content, presence: true
  validates :correct_answer_id, presence: true
  validates :free_response, length: { maximum: 10000 }

  validate :free_response_required, on: :update
  validate :valid_answer, :no_feedback

  delegate :uid, :questions, :question_formats, :question_answers, :question_answer_ids,
           :correct_question_answers, :correct_question_answer_ids, :feedback_map, :solutions,
           :content_hash_for_students, :tags, :los, :aplos, to: :parser

  # We depend on the parser because we do not save the parsed content
  def parser
    @parser ||= OpenStax::Exercises::V1::Exercise.new(content: content)
  end

  def has_correctness?
    true
  end

  def has_content?
    true
  end

  def is_correct?
    correct_answer_id == answer_id
  end

  def exercise?
    true
  end

  def handle_task_step_completion!
    free_response_required
    answer_id_required
    SendTaskedExerciseAnswerToExchange.perform_later(tasked_exercise: self) if errors.empty?
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

  # The following 4 methods assume only 1 Question; this is OK for TaskedExercise,
  # because each TE contains at most 1 part of a multipart exercise.
  def formats
    question_formats[0]
  end

  def answer_ids
    question_answer_ids[0]
  end

  def solution
    solutions[0].try(:first)
  end

  def feedback
    feedback_map[answer_id] || ''
  end

  def set_correct_answer_id
    return correct_answer_id if correct_answer_id.present?

    self.correct_answer_id = correct_question_answer_ids[0].first
  end

  protected

  def free_response_required
    return true unless formats.include?('free-response') && free_response.blank?
    errors.add(:free_response, 'is required')
    false
  end

  def answer_id_required
    return true unless answer_id.blank?
    errors.add(:answer_id, 'is required')
    false
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
