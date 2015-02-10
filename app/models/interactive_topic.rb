class InteractiveTopic < ActiveRecord::Base
  belongs_to :topic
  belongs_to :interactive

  validates :topic, presence: true
  validates :interactive, presence: true, uniqueness: { scope: :topic_id }
end
