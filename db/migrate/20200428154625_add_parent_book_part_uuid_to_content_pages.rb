class AddParentBookPartUuidToContentPages < ActiveRecord::Migration[5.2]
  def change
    add_column :content_pages, :parent_book_part_uuid, :uuid

    reversible do |dir|
      dir.up do
        Content::Models::Book.find_each do |book|
          update_tree_and_pages! book.tree

          book.save!
        end

        change_column_null :content_pages, :parent_book_part_uuid, false

        add_index :content_pages, :parent_book_part_uuid
      end
    end
  end

  def update_tree_and_pages!(tree)
    pages, non_pages = tree['children'].partition { |child| child['type'] == 'Page' }

    Content::Models::Page.where(id: pages.map { |page| page['id'] }).update_all(
      parent_book_part_uuid: tree['uuid']
    )

    non_pages.each do |book_part|
      book_part['uuid'] ||= book_part['tutor_uuid']

      update_tree_and_pages! book_part
    end
  end
end
