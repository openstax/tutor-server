class Task::TaskedExercise < Entity

  wraps Tasks::Models::TaskedExercise

  exposes :url, :title, :content, :exercise, :task_step, :los,
          :answer_id, :answer_ids, :free_response, :transaction

  delegate :uid, :questions, :question_formats, :question_answers, :question_answer_ids,
           :correct_question_answers, :correct_question_answer_ids,
           :content_without_correctness, to: :parser

  # These 2 methods (hacks) will eventually move to Task when we have wrappers for those
  # so that this class is not directly exposed
  def initialize(t = {})
    t.is_a?(Tasks::Models::TaskedExercise) ? super(t) : super(TaskExercise[t])
  end

  def self.temp_hack(t)
    t.is_a?(Tasks::Models::TaskedExercise) ? new(t).passthrough : t
  end

  def handle_task_step_completion!
    # Currently assuming only one question per tasked_exercise, see also correct_answer_id
    question = questions.first
    # "trial" is set to only "0" for now.  When multiple
    # attempts are supported, it will be incremented to indicate the attempt #

    ## Blatant hack below (the identifier *should* be set to
    ## the exchange identifier in the current user's profile,
    ## but the role id is a close temporary proxy):
    OpenStax::Exchange.record_multiple_choice_answer(identifier, url, trial, answer_id)
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
    repository.content = json_hash.to_json
  end

  # The following methods assume only 1 Question
  def correct_answer_id
    correct_question_answer_ids[0][0]
  end

  def feedback
    feedback_for(answer_id)
  end

  def is_correct?
    answer_is_correct?(answer_id)
  end

  def can_be_recovered?
    repository.can_be_recovered
  end

  protected

  def parser
    repository.parser
  end

  def feedback_for(answer_id)
    parser.feedback_map[answer_id] || ''
  end

  def answer_is_correct?(answer_id)
    correct_question_answer_ids.flatten.include?(answer_id)
  end

  def identifier
    repository.task_step.task.taskings.first.role.id
  end

  def trial
    repository.task_step.id.to_s
  end
  
end
