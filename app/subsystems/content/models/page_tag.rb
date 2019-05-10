class Content::Models::PageTag < IndestructibleRecord
  belongs_to :page, inverse_of: :page_tags
  belongs_to :tag, inverse_of: :page_tags

  validates :tag, uniqueness: { scope: :content_page_id }
end
