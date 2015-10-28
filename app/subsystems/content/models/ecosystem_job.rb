module Content
  module Models
    class EcosystemJob < Tutor::SubSystems::BaseModel
      scope :incomplete, -> { where(completed: false) }

      def self.update_status
        incomplete.each do |ecosystem_job|
          job_id = ecosystem_job.import_job_uuid
          job = Lev::BackgroundJob.find(job_id)
          ecosystem_job.update_attributes(completed: true) if job.completed?
        end
      end
    end
  end
end
