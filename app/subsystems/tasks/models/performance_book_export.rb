module Tasks::Models
  class PerformanceBookExport < Tutor::SubSystems::BaseModel
    mount_uploader :export, ExportUploader

    default_scope { order('created_at DESC') }

    belongs_to :course, subsystem: :entity
    belongs_to :role, subsystem: :entity

    def filename
      export.file.identifier
    end

    def url
      export.url
    end
  end
end
