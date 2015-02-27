class Content::Topic < ActiveRecord::Base
  has_many :page_topics, dependent: :destroy #, class_name: '::Content::PageTopic'
  # has_many :exercise_topics, dependent: :destroy

  validates :name, presence: true
end
