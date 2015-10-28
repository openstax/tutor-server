class CreateContentEcosystemJobs < ActiveRecord::Migration
  def change
    create_table :content_ecosystem_jobs do |t|
      t.string :import_job_uuid, null: false
      t.boolean :completed, default: false
    end
  end
end
