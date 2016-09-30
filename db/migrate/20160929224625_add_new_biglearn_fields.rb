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

    add_column :entity_courses, :sequence_number, :integer, null: false, default: '0'
    add_column :tasks_tasks, :sequence_number, :integer, null: false, default: '0'
  end
end
