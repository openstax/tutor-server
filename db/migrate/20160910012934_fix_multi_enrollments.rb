class FixMultiEnrollments < ActiveRecord::Migration
  def up
    Rake::Task[:fix_multi_enrollments].invoke('real')
  end

  def down
  end
end
