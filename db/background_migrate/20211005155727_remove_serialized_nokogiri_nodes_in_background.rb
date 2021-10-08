class RemoveSerializedNokogiriNodesInBackground < ActiveRecord::Migration[5.2]
  BATCH_SIZE = 100

  disable_ddl_transaction!

  def up
    loop do
      break if Content::Models::Page.where(
        '"fragments" ILIKE \'%\\\\nnode: !ruby/object:Nokogiri::HTML::DocumentFragment {}\\\\n%\''
      ).limit(BATCH_SIZE).update_all(
        <<~UPDATE_SQL
          "fragments" = REPLACE(
            "fragments", '\\nnode: !ruby/object:Nokogiri::HTML::DocumentFragment {}\\n', '\\n'
          )
        UPDATE_SQL
      ) < BATCH_SIZE
    end
  end

  def down
  end
end
