class AddConceptCoachPoolToContentPages < ActiveRecord::Migration
  def change
    add_column :content_pages, :content_concept_coach_pool_id, :integer
  end
end
