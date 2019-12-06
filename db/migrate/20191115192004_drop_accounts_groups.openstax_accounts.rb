# This migration comes from openstax_accounts (originally 15)
class DropAccountsGroups < ActiveRecord::Migration[5.2]
  def change
    drop_table "openstax_accounts_group_members" do |t|
      t.integer "group_id", null: false
      t.integer "user_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["group_id", "user_id"], name: "index_openstax_accounts_group_members_on_group_id_and_user_id", unique: true
      t.index ["user_id"], name: "index_openstax_accounts_group_members_on_user_id"
    end

    drop_table "openstax_accounts_group_nestings" do |t|
      t.integer "member_group_id", null: false
      t.integer "container_group_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["container_group_id"], name: "index_openstax_accounts_group_nestings_on_container_group_id"
      t.index ["member_group_id"], name: "index_openstax_accounts_group_nestings_on_member_group_id", unique: true
    end

    drop_table "openstax_accounts_group_owners" do |t|
      t.integer "group_id", null: false
      t.integer "user_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["group_id", "user_id"], name: "index_openstax_accounts_group_owners_on_group_id_and_user_id", unique: true
      t.index ["user_id"], name: "index_openstax_accounts_group_owners_on_user_id"
    end

    drop_table "openstax_accounts_groups" do |t|
      t.integer "openstax_uid", null: false
      t.boolean "is_public", default: false, null: false
      t.string "name"
      t.text "cached_subtree_group_ids"
      t.text "cached_supertree_group_ids"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["is_public"], name: "index_openstax_accounts_groups_on_is_public"
      t.index ["openstax_uid"], name: "index_openstax_accounts_groups_on_openstax_uid", unique: true
    end
  end
end
