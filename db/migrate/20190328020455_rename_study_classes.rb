class RenameStudyClasses < ActiveRecord::Migration
  def up
    execute "update research_study_brains set type = 'Research::Models::ModifiedTasked' where type = 'Research::Models::ModifiedTaskedForUpdate'"
    execute "update research_study_brains set type = 'Research::Models::ModifiedTask' where type = 'Research::Models::ModifiedTaskForDisplay'"
  end

  def down
    execute "update research_study_brains set type = 'Research::Models::ModifiedTaskedForUpdate' where type = 'Research::Models::ModifiedTasked'"
    execute "update research_study_brains set type = 'Research::Models::ModifiedTaskForDisplay' where type = 'Research::Models::ModifiedTask'"
  end
end
