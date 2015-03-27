class Content::Models::PageTag < Tutor::SubSystems::BaseModel
  belongs_to :page
  belongs_to :tag

  validates :page, presence: true
  validates :tag, presence: true, uniqueness: { scope: :content_page_id }
end
