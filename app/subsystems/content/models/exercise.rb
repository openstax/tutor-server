class Content::Models::Exercise < Tutor::SubSystems::BaseModel
  acts_as_resource

  wrapped_by ::Exercise

  has_many :exercise_tags, dependent: :destroy

  has_many :tasked_exercises, subsystem: :tasks, primary_key: :url, foreign_key: :url

  has_many :tags, through: :exercise_tags

  delegate :uid, :questions, :question_formats, :question_answers, :question_answer_ids,
           :correct_question_answers, :correct_question_answer_ids, :feedback_map,
           :content_without_correctness, :tags, :los, to: :parser

  # We depend on the parser because we do not save the parsed content
  def parser
    @parser ||= OpenStax::Exercises::V1::Exercise.new(content)
  end

  def tags_with_teks
    # Include tek tags
    tags.collect { |t| [t, t.teks_tags] }.flatten.uniq
  end
end
