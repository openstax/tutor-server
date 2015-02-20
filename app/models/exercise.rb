class Exercise < ActiveRecord::Base
  acts_as_resource

  has_many :exercise_topics, dependent: :destroy

  delegate :title, :answers, :correct_answer_id, :feedback_map, :feedback_html,
           to: :wrapper

  def wrapper
    @wrapper ||= OpenStax::Exercises::V1::Exercise.new(url, content)
  end
end
