module Manager::EcosystemsActions
  def self.included(base)
    base.before_action :get_ecosystem, only: [ :manifest ]
  end

  def index
    @ecosystems = Content::ListEcosystems[]
    result = CollectJobsData.call job_name: 'ImportEcosystemManifest'
    @incomplete_jobs = result.outputs.incomplete_jobs
    @failed_jobs = result.outputs.failed_jobs
  end

  def manifest
    filename = "#{FilenameSanitizer.sanitize(@ecosystem.title)}.yml"
    send_data @ecosystem.manifest.to_yaml, filename: filename
  end

  protected

  def get_ecosystem
    @ecosystem = Content::Models::Ecosystem.find(params[:id])
  end
end
