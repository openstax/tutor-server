class Content::Models::PageTopic < Tutor::SubSystems::BaseModel
  sortable_belongs_to :page, on: :number, inverse_of: :page_topics
  belongs_to :topic

  validates :page, presence: true
  validates :topic, presence: true, uniqueness: { scope: :content_page_id }
end
