class Topic < ActiveRecord::Base
  belongs_to :klass

  has_many :exercise_topics, dependent: :destroy

  validates :klass, presence: true
end
