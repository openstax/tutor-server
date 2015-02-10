class Book < ActiveRecord::Base
  sortable_belongs_to :parent_book, on: :number,
                                    class_name: 'Book',
                                    inverse_of: :child_books

  has_many :child_books, class_name: 'Book',
                         dependent: :destroy,
                         inverse_of: :parent_book

  has_many :pages, dependent: :destroy

  validates :title, presence: true
  validates :cnx_id, presence: true
  validates :version, presence: true, uniqueness: { scope: :cnx_id }
end
