class Content::PageTag < ActiveRecord::Base
  sortable_belongs_to :page, on: :number, inverse_of: :page_tags
  belongs_to :tag

  validates :page, presence: true
  validates :tag, presence: true, uniqueness: { scope: :content_page_id }
end
