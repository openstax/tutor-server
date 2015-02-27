class Content::BookPart < ActiveRecord::Base
  acts_as_resource allow_nil: true

  belongs_to :book, subsystem: :entity

  sortable_belongs_to :parent_book_part, on: :number,
                                         class_name: '::Content::BookPart',
                                         inverse_of: :child_book_parts,
                                         foreign_key: "parent_book_part_id"

  has_many :child_book_parts, class_name: '::Content::BookPart',
                              foreign_key: 'parent_book_part_id',
                              dependent: :destroy,
                              inverse_of: :parent_book_part

  has_many :pages, dependent: :destroy, 
                   inverse_of: :book_part

  validates :title, presence: true
end
