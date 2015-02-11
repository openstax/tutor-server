class PageTopic < ActiveRecord::Base
  sortable_belongs_to :page, on: :number, inverse_of: :page_topics
  belongs_to :topic

  validates :page, presence: true
  validates :topic, presence: true, uniqueness: { scope: :page_id }
end
