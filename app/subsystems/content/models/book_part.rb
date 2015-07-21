class Content::Models::BookPart < Tutor::SubSystems::BaseModel
  acts_as_resource allow_nil: true

  serialize :chapter_section, Array
  serialize :toc_cache, Hash
  serialize :page_data_cache, Array

  belongs_to :book, subsystem: :entity

  sortable_belongs_to :parent_book_part, on: :number,
                                         class_name: '::Content::Models::BookPart',
                                         inverse_of: :child_book_parts,
                                         foreign_key: "parent_book_part_id"

  sortable_has_many :child_book_parts, on: :number,
                                       class_name: '::Content::Models::BookPart',
                                       foreign_key: 'parent_book_part_id',
                                       dependent: :destroy,
                                       inverse_of: :parent_book_part

  sortable_has_many :pages, on: :number,
                            dependent: :destroy,
                            inverse_of: :book_part

  validates :title, presence: true
  validates :book, presence: true

  def self.root_for(book_id:)
    find_by(entity_book_id: book_id, parent_book_part_id: nil)
  end

end
