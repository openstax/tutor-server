class AddNewBiglearnFields < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'

    add_column :content_ecosystems, :tutor_uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :content_books, :tutor_uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :content_chapters, :tutor_uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :content_pages, :tutor_uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :content_exercises, :tutor_uuid, :uuid, null: false, default: 'uuid_generate_v4()'

    add_column :entity_courses, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :course_membership_periods, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :course_membership_students, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :tasks_tasks, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_column :tasks_tasked_exercises, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'

    add_column :entity_courses, :sequence_number, :integer, null: false, default: '0'
    add_column :tasks_tasks, :sequence_number, :integer, null: false, default: '0'

    add_index :content_ecosystems, :tutor_uuid, unique: true
    add_index :content_books, :tutor_uuid, unique: true
    add_index :content_chapters, :tutor_uuid, unique: true
    add_index :content_pages, :tutor_uuid, unique: true
    add_index :content_exercises, :tutor_uuid, unique: true

    add_index :entity_courses, :uuid, unique: true
    add_index :course_membership_periods, :uuid, unique: true
    add_index :course_membership_students, :uuid, unique: true
    add_index :tasks_tasks, :uuid, unique: true
    add_index :tasks_tasked_exercises, :uuid, unique: true
  end
end
