class Content::Models::Topic < Tutor::SubSystems::BaseModel
  has_many :page_topics, dependent: :destroy
  has_many :exercise_topics, dependent: :destroy

  validates :name, presence: true
end
