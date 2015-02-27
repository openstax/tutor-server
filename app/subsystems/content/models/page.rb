class Content::Page < ActiveRecord::Base
  acts_as_resource

  sortable_belongs_to :book_part, on: :number, 
                                  inverse_of: :pages

  belongs_to :book, subsystem: :entity

  has_many :page_topics, dependent: :destroy

  validates :title, presence: true
end
