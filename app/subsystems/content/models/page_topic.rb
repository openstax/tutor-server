class Content::PageTopic < ActiveRecord::Base
  sortable_belongs_to :content_page, on: :number, inverse_of: :page_topics, class_name: '::Content::Page'
  belongs_to :content_topic, class_name: '::Content::Topic'

  validates :content_page, presence: true
  validates :content_topic, presence: true, uniqueness: { scope: :content_page_id }
end
