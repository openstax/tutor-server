class CreateCourseContentCourseBooks < ActiveRecord::Migration
  def change
    create_table :course_content_course_books do |t|
      t.integer :entity_course_id, null: false
      t.integer :entity_book_id, null: false
      t.timestamps null: false

      t.index [:entity_course_id, :entity_book_id], unique: true, name: ['course_books_course_id_on_book_id_unique']
      t.index :entity_book_id
    end

    add_foreign_key :course_content_course_books, :entity_courses
    add_foreign_key :course_content_course_books, :entity_books
  end
end
