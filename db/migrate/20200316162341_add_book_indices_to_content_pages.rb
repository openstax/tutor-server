class AddBookIndicesToContentPages < ActiveRecord::Migration[5.2]
  def set_book_indices(part, book_indices = [])
    if part.is_a? Content::Page
      Content::Models::Page.where(id: part.id).update_all book_indices: book_indices
    else
      part.children.each_with_index do |child, index|
        set_book_indices child, book_indices + [ index ]
      end
    end
  end

  def change
    add_column :content_pages, :book_indices, :integer, array: true

    reversible do |dir|
      dir.up do
        Content::Models::Book.find_each { |book| set_book_indices book }

        change_column_null :content_pages, :book_indices, false
      end
    end
  end
end
