module Tasks::Models
  class PerformanceReportExport < IndestructibleRecord
    mount_uploader :export, ExportUploader

    default_scope { order created_at: :desc }

    belongs_to :course, subsystem: :course_profile
    belongs_to :role,   subsystem: :entity

    def filename
      export.file.filename
    end

    def url
      export.url
    end
  end
end
