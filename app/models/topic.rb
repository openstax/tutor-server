class Topic < ActiveRecord::Base
  has_many :resource_topics, dependent: :destroy

  validates :name, presence: true
end
