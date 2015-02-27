class Content::PageTopic < ActiveRecord::Base
  sortable_belongs_to :page, on: :number, inverse_of: :page_topics #, class_name: '::Content::Page'  

  # belongs_to :page, inverse_of: :page_topics #, class_name: '::Content::Page'  

  # debugger
  belongs_to :topic #, class_name: '::Content::Topic'

  validates :page, presence: true
  validates :topic, presence: true, uniqueness: { scope: :content_page_id }
end
