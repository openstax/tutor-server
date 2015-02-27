class Content::Page < ActiveRecord::Base
  acts_as_resource

  sortable_belongs_to :book, on: :number, 
                             inverse_of: :pages

  belongs_to :entity_book, class_name: '::Entity::Book', 
                           foreign_key: 'entity_book_id'

  has_many :page_topics, dependent: :destroy

  validates :title, presence: true
end
