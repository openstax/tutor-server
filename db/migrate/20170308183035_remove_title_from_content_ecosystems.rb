class RemoveTitleFromContentEcosystems < ActiveRecord::Migration
  def up
    remove_column :content_ecosystems, :title
  end

  def down
    add_column :content_ecosystems, :title, :string

    Content::Models::Ecosystem.find_each do |ecosystem|
      books = ecosystem.books
      next if books.empty?

      title = "#{books.map(&:title).join('; ')} (#{books.map(&:cnx_id).join('; ')})"
      ecosystem.update_attribute :title, title
    end

    change_column_null :content_ecosystems, :title, false, 'Empty Ecosystem'
  end
end
