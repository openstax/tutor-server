class TaskedExercise < ActiveRecord::Base
  acts_as_tasked

  validates :url, presence: true
  validates :content, presence: true

  delegate :answers, :correct_answer_id, :feedback_map, to: :wrapper

  def wrapper
    @wrapper ||= OpenStax::Exercises::V1::Exercise.new(url, content)
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
end
