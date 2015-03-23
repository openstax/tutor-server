class Content::BookPart < ActiveRecord::Base
  acts_as_resource allow_nil: true

  belongs_to :book, subsystem: :entity

  sortable_belongs_to :parent_book_part, on: :number,
                                         class_name: '::Content::BookPart',
                                         inverse_of: :child_book_parts,
                                         foreign_key: "parent_book_part_id"

  sortable_has_many :child_book_parts, on: :number,
                                       class_name: '::Content::BookPart',
                                       foreign_key: 'parent_book_part_id',
                                       dependent: :destroy,
                                       inverse_of: :parent_book_part

  sortable_has_many :pages, on: :number,
                            dependent: :destroy,
                            inverse_of: :book_part

  validates :title, presence: true

  def self.root_for(book_id:)
    where(entity_book_id: book_id).where(parent_book_part_id: nil).first
  end

  def visit(visitors)
    child_book_part_includes = []
    page_includes = []

    visitors.each do |visitor|
      visitor.visit(self)
      child_book_part_includes.push(visitor.book_part_includes)
      page_includes.push(visitor.page_includes)
    end

    visitors.each{|visitor| visitor.descend}

    pages.includes(page_includes.uniq).each do |page|
      page.visit(visitors)
    end

    child_book_parts.includes(child_book_part_includes.uniq).each do |child_book_part|
      child_book_part.visit(visitors)
    end

    visitors.each{|visitor| visitor.ascend}
  end
end
