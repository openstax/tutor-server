class CreateLtiResourceLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :lti_resource_links do |t|
      t.references :lti_platform, null: false, index: false, foreign_key: {
        on_update: :cascade, on_delete: :cascade
      }
      t.string :context_id, null: false
      t.string :resource_link_id, null: false
      t.string :lineitems_endpoint
      t.string :lineitem_endpoint
      t.boolean :can_create_lineitems, null: false
      t.boolean :can_update_scores, null: false

      t.timestamps

      t.index [ :lti_platform_id, :context_id, :resource_link_id ], unique: true,
              name: 'index_lti_resource_links_on_platform_context_and_id'
    end
  end
end
