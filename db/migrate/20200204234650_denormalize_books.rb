class DenormalizeBooks < ActiveRecord::Migration[5.2]
  def up
    add_reference :content_pages, :content_book, foreign_key: {
      to_table: :content_books, on_update: :cascade, on_delete: :cascade
    }

    Content::Models::Page.update_all(
      <<~UPDATE_SQL
        "content_book_id" = "content_chapters"."content_book_id"
        FROM "content_chapters"
        WHERE "content_chapters"."id" = "content_pages"."content_chapter_id"
      UPDATE_SQL
    )

    change_column_null :content_pages, :content_book_id, false

    add_column :content_books, :tree, :jsonb

    add_column :content_pages, :all_exercise_ids,              :integer,
               array: true, default: [], null: false
    add_column :content_pages, :reading_dynamic_exercise_ids,  :integer,
               array: true, default: [], null: false
    add_column :content_pages, :reading_context_exercise_ids,  :integer,
               array: true, default: [], null: false
    add_column :content_pages, :homework_core_exercise_ids,    :integer,
               array: true, default: [], null: false
    add_column :content_pages, :homework_dynamic_exercise_ids, :integer,
               array: true, default: [], null: false
    add_column :content_pages, :practice_widget_exercise_ids,  :integer,
               array: true, default: [], null: false

    Content::Models::Page.update_all(
      <<~UPDATE_SQL
        "all_exercise_ids" = ARRAY(
          SELECT json_array_elements("content_exercise_ids"::json)::text::int
          FROM "content_pools"
          WHERE "content_pools"."id" = "content_pages"."content_all_exercises_pool_id"
        ),
        "reading_dynamic_exercise_ids" = ARRAY(
          SELECT json_array_elements("content_exercise_ids"::json)::text::int
          FROM "content_pools"
          WHERE "content_pools"."id" = "content_pages"."content_reading_dynamic_pool_id"
        ),
        "reading_context_exercise_ids" = ARRAY(
          SELECT json_array_elements("content_exercise_ids"::json)::text::int
          FROM "content_pools"
          WHERE "content_pools"."id" = "content_pages"."content_reading_context_pool_id"
        ),
        "homework_core_exercise_ids" = ARRAY(
          SELECT json_array_elements("content_exercise_ids"::json)::text::int
          FROM "content_pools"
          WHERE "content_pools"."id" = "content_pages"."content_homework_core_pool_id"
        ),
        "homework_dynamic_exercise_ids" = ARRAY(
          SELECT json_array_elements("content_exercise_ids"::json)::text::int
          FROM "content_pools"
          WHERE "content_pools"."id" = "content_pages"."content_homework_dynamic_pool_id"
        ),
        "practice_widget_exercise_ids" = ARRAY(
          SELECT json_array_elements("content_exercise_ids"::json)::text::int
          FROM "content_pools"
          WHERE "content_pools"."id" = "content_pages"."content_practice_widget_pool_id"
        )
      UPDATE_SQL
    )

    remove_column :content_pages, :content_reading_dynamic_pool_id
    remove_column :content_pages, :content_reading_context_pool_id
    remove_column :content_pages, :content_homework_core_pool_id
    remove_column :content_pages, :content_homework_dynamic_pool_id
    remove_column :content_pages, :content_practice_widget_pool_id
    remove_column :content_pages, :content_all_exercises_pool_id
    remove_column :content_pages, :content_concept_coach_pool_id

    # All old books have no Units and only Chapters
    Content::Models::Book.preload(:pages).find_each do |book|
      exercise_uuids_by_page_id = Hash.new { |hash, key| hash[key] = [] }
      Content::Models::Exercise.where(content_page_id: book.pages.map(&:id))
                               .pluck(:content_page_id, :uuid).each do |ex|
        exercise_uuids_by_page_id[ex.first] << ex.second
      end
      pages_by_chapter_id = book.pages.sort_by(&:book_location).group_by(&:content_chapter_id)
      chapters_by_id = ActiveRecord::Base.connection.execute(
        <<~CHAPTER_SQL
          SELECT "id", "title", "baked_book_location", "tutor_uuid"
          FROM "content_chapters"
          WHERE "id" IN (#{pages_by_chapter_id.keys.join(', ')})
        CHAPTER_SQL
      ).to_a.index_by { |chapter| chapter['id'] }

      book.tree = {
        type: 'Book',
        title: book.title,
        book_location: [],
        id: book.id,
        uuid: book.uuid,
        version: book.version,
        tutor_uuid: book.tutor_uuid,
        children: pages_by_chapter_id.map do |chapter_id, pages|
          chapter = chapters_by_id[chapter_id]

          {
            type: 'Chapter',
            title: chapter['title'],
            book_location: chapter['baked_book_location'],
            tutor_uuid: chapter['tutor_uuid'],
            children: pages.map do |page|
              {
                type: 'Page',
                title: page.title,
                book_location: page.baked_book_location || [],
                id: page.id,
                uuid: page.uuid,
                version: page.version,
                short_id: page.short_id,
                tutor_uuid: page.tutor_uuid
              }.tap do |pg|
                Content::Models::Page.pool_types.each do |pool_type|
                  pool_method_name = "#{pool_type}_exercise_ids".to_sym
                  pg[pool_method_name] = page.public_send pool_method_name
                end
              end
            end
          }.tap do |ch|
            Content::Models::Page.pool_types.each do |pool_type|
              pool_method_name = "#{pool_type}_exercise_ids".to_sym
              ch[pool_method_name] = ch[:children].flat_map { |child| child[pool_method_name] }.uniq
            end
          end
        end
      }.deep_stringify_keys
      Content::Models::Page.pool_types.each do |pool_type|
        pool_method_name = "#{pool_type}_exercise_ids"
        book.tree[pool_method_name] = book.tree['children'].flat_map do |child|
          child[pool_method_name]
        end.uniq
      end

      book.save!
    end

    change_column_null :content_books, :tree, false

    remove_column :content_pages, :content_chapter_id
    remove_column :content_pages, :number

    remove_column :content_pages, :book_location
    rename_column :content_pages, :baked_book_location, :book_location

    remove_column :tasks_tasked_readings, :book_location
    rename_column :tasks_tasked_readings, :baked_book_location, :book_location

    drop_table :content_chapters
    drop_table :content_pools
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
