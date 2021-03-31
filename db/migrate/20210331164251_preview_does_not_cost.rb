class PreviewDoesNotCost < ActiveRecord::Migration[5.2]
  def up
    CourseProfile::Models::Course.where(
      is_preview: true, does_cost: true
    ).update_all(does_cost: false)
  end

  def down
  end
end
