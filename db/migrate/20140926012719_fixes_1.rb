class Fixes1 < ActiveRecord::Migration
  def change
    # These are already accounted for as the first column in multi-column indices
    remove_index :course_managers, :user_id
    remove_index :school_managers, :user_id
    remove_index :educators, :user_id
    remove_index :students, :user_id

    add_index :sections, [:name, :klass_id], unique: true

    add_index :students, :level
  end
end
