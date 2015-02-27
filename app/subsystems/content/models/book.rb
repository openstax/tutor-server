class Content::Book < ActiveRecord::Base
  acts_as_resource allow_nil: true

  sortable_belongs_to :parent_book, on: :number,
                                    class_name: '::Content::Book',
                                    inverse_of: :child_books,
                                    foreign_key: "parent_book_id"

  belongs_to :entity_book, class_name: '::Entity::Book', 
                           foreign_key: 'entity_book_id'


  has_many :child_books, class_name: '::Content::Book',
                         foreign_key: :parent_book_id,
                         dependent: :destroy,
                         inverse_of: :parent_book

  has_many :pages, dependent: :destroy, 
                   inverse_of: :book

  validates :title, presence: true
end
