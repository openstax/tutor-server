class Content::Page < ActiveRecord::Base
  acts_as_resource

  sortable_belongs_to :book, on: :number, 
                                     inverse_of: :pages #,
                                     # class_name: "::Content::Book"

  has_many :page_topics, dependent: :destroy #,
                         # class_name: "::Content::PageTopic"

  validates :title, presence: true
end
