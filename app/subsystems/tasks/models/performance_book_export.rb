module Tasks::Models
  class PerformanceBookExport < Tutor::SubSystems::BaseModel
    default_scope { order('created_at DESC') }

    belongs_to :course, subsystem: :entity
    belongs_to :role, subsystem: :entity

    def filepath
      "/tmp/#{filename}.#{extension}"
    end

    private
    def extension
      'xlsx'
    end
  end
end
