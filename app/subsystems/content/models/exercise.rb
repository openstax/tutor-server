class Content::Models::Exercise < Tutor::SubSystems::BaseModel
  acts_as_resource

  wrapped_by ::Exercise

  has_many :exercise_tags, dependent: :destroy

  has_many :tasked_exercises, subsystem: :tasks, primary_key: :url, foreign_key: :url

  has_many :tags, through: :exercise_tags

  has_many :same_number, class_name: "Content::Models::Exercise",
                         primary_key: :number,
                         foreign_key: :number

  scope :latest, -> { joins(:same_number)
                        .group(same_number: :number)
                        .having{version == max(same_number.version)} }

  def uid
    "#{number}@#{version}"
  end

  def tags_with_teks
    # Include tek tags
    tags.collect { |t| [t, t.teks_tags] }.flatten.uniq
  end
end
