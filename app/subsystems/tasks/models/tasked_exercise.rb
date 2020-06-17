class Tasks::Models::TaskedExercise < IndestructibleRecord
  attr_writer :available_points

  acts_as_tasked

  auto_uuid

  belongs_to :exercise, subsystem: :content, inverse_of: :tasked_exercises

  before_validation :set_correct_answer_id, on: :create, if: :has_answers?

  validates :url, :question_id, :question_index, :content, presence: true
  validates :correct_answer_id, presence: true, if: :has_answers?
  validates :free_response, length: { maximum: 10000 }
  validates :grader_points, numericality: { greater_than_or_equal_to: 0.0, allow_nil: true }

  validate :free_response_required_before_answer_id, on: :update
  validate :valid_answer, :changes_allowed

  scope :correct, -> do
    where('tasks_tasked_exercises.answer_id = tasks_tasked_exercises.correct_answer_id')
  end
  scope :incorrect, -> do
    where('tasks_tasked_exercises.answer_id != tasks_tasked_exercises.correct_answer_id')
  end
  scope :manually_graded, -> { where('CARDINALITY("answer_ids") = 0') }

  # Fields shared by all parts of a multipart exercise
  delegate :uid, :tags, :los, :aplos, to: :exercise

  # Fields specific to each part of a multipart exercise
  delegate :questions, :question_formats, :question_answers,
           :question_answer_ids, :question_formats_for_students,
           :correct_question_answers, :correct_question_answer_ids,
           :feedback_map, :solutions, :content_hash_for_students, to: :parser

  def context
    super || exercise.context
  end

  def content
    cont = super
    return cont unless cont.nil?

    return if question_index.nil?

    questions = exercise&.questions
    return if questions.nil?

    question = questions[question_index]
    return if question.nil?

    question.content
  end

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
    if grader_points.nil?
      !correct_answer_id.nil? && answer_id == correct_answer_id
    else
      grader_points > 0
    end
  end

  def exercise?
    true
  end

  def before_completion
    return unless has_answer_missing?

    errors.add(:answer_id, 'is required')
    throw :abort
  end

  def make_correct!
    self.free_response = '.'
    self.answer_id = correct_answer_id
    self.save!
  end

  def make_incorrect!
    self.free_response = '.'
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

  def available_points
    @available_points ||= begin
      task = task_step.task
      if task.homework?
        # Inefficient, which is why we preload the available_points in the TaskRepresenter
        task_question_index = task.exercise_and_placeholder_steps.index(task_step)
        task.available_points_per_question_index[task_question_index]
      else
        1.0
      end
    end
  end

  # The following 2 methods assume only 1 Question; this is OK for TaskedExercise,
  # because each TE contains at most 1 part of a multipart exercise.
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

  def allows_free_response?
    return parser.question_formats_for_students.include?('free-response')
  end

  def content_preview
    content_preview_from_json = JSON(content)["questions"].try(:first).try(:[], "stem_html")
    content_preview_from_json || "Exercise step ##{id}"
  end

  def has_answers?
    !answer_ids.empty?
  end
  alias_method :can_be_auto_graded?, :has_answers?

  def has_answer_missing?
    answer_id.blank? && has_answers?
  end

  def full_credit?
    full_credit_question_ids = Set.new(
      task_step.task&.task_plan&.dropped_questions&.filter(&:full_credit?)&.map(&:question_id) || []
    )

    full_credit_question_ids.include? question_id
  end

  # Used directly only when grading
  def grader_points
    gp = super

    gp.nil? && !can_be_auto_graded? && !task_step.completed? && task_step.task.past_due? &&
    task_step.task.course.past_due_unattempted_ungraded_wrq_are_zero ? 0.0 : gp
  end

  def published_grader_points
    case task_step.task.manual_grading_feedback_on
    when 'grade'
      grader_points
    when 'publish'
      super
    else
      nil
    end
  end

  def points_without_lateness
    return available_points if full_credit?

    return grader_points unless grader_points.nil?

    task = task_step.task
    if task_step.completed?
      return unless can_be_auto_graded?

      task = task_step.task
      completion_weight = task.course&.pre_wrm_scores? ? 0.0 : task.completion_weight
      available_points * (answer_id == correct_answer_id ? 1.0 : completion_weight)
    else
      past_due = task_step.task.past_due? if past_due.nil?
      past_due ? 0.0 : nil
    end
  end

  def published_points_without_lateness(past_due: nil)
    return available_points if full_credit?

    return published_grader_points unless published_grader_points.nil?

    task = task_step.task
    past_due = task.past_due? if past_due.nil?

    if task_step.completed?
      return unless can_be_auto_graded?

      auto_grading_feedback_available = task.auto_grading_feedback_available?(past_due: past_due) \
        if auto_grading_feedback_available.nil?
      return unless auto_grading_feedback_available

      completion_weight = task.course&.pre_wrm_scores? ? 0.0 : task.completion_weight
      available_points * (answer_id == correct_answer_id ? 1.0 : completion_weight)
    else
      past_due ? 0.0 : nil
    end
  end

  def late_work_fraction_penalty
    return 0.0 if task_step.last_completed_at.nil?

    task = task_step.task
    due_at = task.due_at
    return 0.0 if due_at.nil? || task_step.last_completed_at <= due_at

    penalty = case task.late_work_penalty_applied
    when 'immediately'
      task.late_work_penalty_per_period
    when 'daily'
      [
        ((task_step.last_completed_at - due_at)/1.day).ceil * task.late_work_penalty_per_period, 1.0
      ].min
    when 'not_accepted'
      1.0
    else
      0.0
    end
  end

  def late_work_point_penalty
    penalty = late_work_fraction_penalty
    return 0.0 if penalty == 0.0

    pts = points_without_lateness
    return 0.0 if pts.nil? || pts == 0.0

    pts * penalty
  end

  def published_late_work_point_penalty(past_due: nil)
    penalty = late_work_fraction_penalty
    return 0.0 if penalty == 0.0

    pts = published_points_without_lateness(past_due: past_due)
    return 0.0 if pts.nil? || pts == 0.0

    pts * penalty
  end

  def points
    pts = points_without_lateness

    pts - late_work_point_penalty unless pts.nil?
  end

  def published_points(past_due: nil)
    pts = published_points_without_lateness(past_due: past_due)
    pts - published_late_work_point_penalty(past_due: past_due) unless pts.nil?
  end

  def published_comments
    case task_step.task.manual_grading_feedback_on
    when 'grade'
      grader_comments
    when 'publish'
      super
    else
      nil
    end
  end

  def was_manually_graded?
    !last_graded_at.nil?
  end

  def needs_grading?
    completed? && !can_be_auto_graded? && !was_manually_graded?
  end

  # NOTE: The following 2 methods do not take into account
  #       automatic publication from the grading_template
  def grade_published?
    was_manually_graded? &&
    grader_points == published_points &&
    grader_comments == published_comments
  end

  def grade_needs_publishing?
    was_manually_graded? && !grade_published?
  end

  def feedback_available?(current_time: Time.current)
    return false unless completed?

    task = task_step.task
    return task.manual_grading_feedback_available? if was_manually_graded?

    can_be_auto_graded? && task.auto_grading_feedback_available?(
      current_time: current_time
    )
  end

  protected

  def free_response_required_before_answer_id
    return if answer_id.blank? || !free_response.blank? || !allows_free_response?

    errors.add(:free_response, 'is required')
    throw :abort
  end

  def valid_answer
    # Multiple choice answer must be listed in the exercise
    return if answer_id.blank? || answer_ids.include?(answer_id.to_s)

    errors.add(:answer_id, 'is not a valid answer id for this problem')
    throw :abort
  end

  def changes_allowed(current_time: Time.current)
    # Cannot change the answer after feedback is available or manually graded
    # Feedback is available immediately for iReadings, or at the due date for HW,
    # but waits until the step is marked as completed
    return if task_step&.can_be_updated?(current_time: current_time)

    [ :answer_id, :free_response ].each do |attr|
      errors.add(
        attr, 'cannot be updated after feedback becomes available or is graded'
      ) if changes[attr].present?
    end

    throw(:abort) if errors.any?
  end
end
