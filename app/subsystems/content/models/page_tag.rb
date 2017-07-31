class Content::Models::PageTag < IndestructibleRecord
  belongs_to :page, inverse_of: :page_tags
  belongs_to :tag, inverse_of: :page_tags

  validates :page, presence: true
  validates :tag, presence: true, uniqueness: { scope: :content_page_id }
end
