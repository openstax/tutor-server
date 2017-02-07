class AddMissingTimestamps < ActiveRecord::Migration
  MODELS_MISSING_TIMESTAMPS = [
    SchoolDistrict::Models::District,
    ShortCode::Models::ShortCode,
    Tasks::Models::TaskedPlaceholder
  ]
  MODELS_WITH_NULLABLE_TIMESTAMPS = [
    Salesforce::Models::AttachedRecord,
    Tasks::Models::PerformanceReportExport
  ]

  def up
    time = Time.current

    MODELS_MISSING_TIMESTAMPS.each do |klass|
      add_timestamps klass.table_name, null: true
      klass.unscoped.update_all({created_at: time, updated_at: time})
    end

    (MODELS_MISSING_TIMESTAMPS + MODELS_WITH_NULLABLE_TIMESTAMPS).each do |klass|
      change_column_null klass.table_name, :created_at, false
      change_column_null klass.table_name, :updated_at, false
    end
  end

  def down
    MODELS_WITH_NULLABLE_TIMESTAMPS.each do |klass|
      change_column_null klass.table_name, :updated_at, true
      change_column_null klass.table_name, :created_at, true
    end

    MODELS_MISSING_TIMESTAMPS.each do |klass|
      remove_timestamps klass.table_name
    end
  end
end
