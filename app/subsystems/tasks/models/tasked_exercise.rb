class Tasks::Models::TaskedExercise < Tutor::SubSystems::BaseModel
  acts_as_tasked

  belongs_to :exercise, subsystem: :content, primary_key: :url, foreign_key: :url

  validates :url, presence: true
  validates :content, presence: true
  validate :valid_state, :valid_answer, :no_feedback

  delegate :uid, :questions, :question_formats, :question_answers, :question_answer_ids,
           :correct_question_answers, :correct_question_answer_ids, :feedback_map,
           :content_hash_without_correctness, :tags, :los, :aplos, to: :parser

  # We depend on the parser because we do not save the parsed content
  def parser
    @parser ||= OpenStax::Exercises::V1::Exercise.new(content: content)
  end

  def handle_task_step_completion!
    # TODO: Do this somewhere else, it does not belong here

    # Currently assuming only one question per tasked_exercise, see also correct_answer_id
    question = questions.first
    # "trial" is set to only "1" for now. When multiple
    # attempts are supported, it will be incremented to indicate the attempt #
    OpenStax::Exchange.record_multiple_choice_answer(identifiers.first, url, trial, answer_id)

    grade = is_correct? ? 1 : 0
    grader = 'tutor'
    OpenStax::Exchange.record_grade(identifiers.first, url, trial, grade, grader)
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

  def identifiers
    roles = task_step.task.taskings.collect{ |t| t.role }
    users = Role::GetUsersForRoles[roles]
    UserProfile::Models::Profile.where(entity_user: users)
                                .collect{ |p| p.exchange_write_identifier }
  end

  def trial
    task_step.id.to_s
  end

  # Eventually this will be enforced by the exercise substeps
  def valid_state
    # Can't answer multiple choice before free response
    # if question formats includes 'free-response'
    return if !free_response.blank? || \
              answer_id.blank? || \
              !formats.include?('free-response')

    errors.add(:free_response, 'must not be blank before entering a multiple choice answer')
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
