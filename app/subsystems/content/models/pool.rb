class Content::Models::Pool < IndestructibleRecord

  wrapped_by ::Content::Strategies::Direct::Pool

  belongs_to :ecosystem, inverse_of: :pools

  enum pool_type: [ :reading_dynamic, :reading_context, :homework_core,
                    :homework_dynamic, :practice_widget, :all_exercises, :concept_coach ]

  json_serialize :content_exercise_ids, Integer, array: true

  validates :pool_type, presence: true
  validates :uuid, presence: true, uniqueness: true

  def exercises
    @exercises ||= {}
    @exercises[content_exercise_ids] ||= Content::Models::Exercise.where(id: content_exercise_ids)
  end

  # This method checks only the array of ids, not the DB records, in order to save time
  def empty?
    content_exercise_ids.empty?
  end

end
