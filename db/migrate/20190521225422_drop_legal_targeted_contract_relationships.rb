class DropLegalTargetedContractRelationships < ActiveRecord::Migration[5.2]
  def up
    drop_table :legal_targeted_contract_relationships
  end

  def down
    create_table :legal_targeted_contract_relationships do |t|
      t.string :child_gid, null: false
      t.string :parent_gid, null: false

      t.timestamps null: false

      t.index [:child_gid, :parent_gid], unique: true, name: 'legal_targeted_contracts_rship_child_parent'
      t.index [:parent_gid], name: 'legal_targeted_contracts_rship_parent'
    end

    SchoolDistrict::Models::School.where.not(school_district_district_id: nil)
                                  .find_each do |school|
      current_time = Time.current.to_s(:db)

      ActiveRecord::Base.connection.execute <<~INSERT_SQL
        INSERT INTO "legal_targeted_contract_relationships"
          ("child_gid", "parent_gid", "created_at", "updated_at")
          VALUES (
            '#{Legal::Utils.gid(school)}',
            '#{Legal::Utils.gid(school.district)}',
            '#{current_time}',
            '#{current_time}'
          )
      INSERT_SQL
    end

    CourseProfile::Models::Course.where.not(school_district_school_id: nil)
                                 .find_each do |course|
      current_time = Time.current.to_s(:db)

      ActiveRecord::Base.connection.execute <<~INSERT_SQL
        INSERT INTO "legal_targeted_contract_relationships"
          ("child_gid", "parent_gid", "created_at", "updated_at")
          VALUES (
            '#{Legal::Utils.gid(course)}',
            '#{Legal::Utils.gid(course.school)}',
            '#{current_time}',
            '#{current_time}'
          )
      INSERT_SQL
    end
  end
end
