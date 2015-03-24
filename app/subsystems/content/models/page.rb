class Content::Page < ActiveRecord::Base
  acts_as_resource

  sortable_belongs_to :book_part, on: :number, inverse_of: :pages

  sortable_has_many :page_topics, on: :number, dependent: :destroy

  validates :title, presence: true
  
end
