class ResourceTopic < ActiveRecord::Base
  sortable_belongs_to :resource, on: :number, inverse_of: :resource_topics
  belongs_to :topic

  validates :resource, presence: true
  validates :topic, presence: true, uniqueness: { scope: :resource_id }
end
