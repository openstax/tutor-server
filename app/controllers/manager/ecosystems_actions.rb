module Manager::EcosystemsActions

  def self.included(base)
    base.before_action :get_ecosystem, only: [:update, :destroy, :manifest]
  end

  def index
    @ecosystems = Content::ListEcosystems[]
    @incomplete_jobs = Jobba.where(state: :incomplete).to_a.select do |job|
      job.data.try :[], 'ecosystem_import_url'
    end
    @failed_jobs = Jobba.where(state: :failed).to_a.select do |job|
      job.data.try :[], 'ecosystem_import_url'
    end
  end

  def new
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Ecosystem)
  end

  def create
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Ecosystem)
    manifest_content = params[:manifest].respond_to?(:read) ? \
                         params[:manifest].read : params[:manifest].to_s
    create_book_import_job(manifest_content, params[:comments])
    flash[:notice] = 'Ecosystem import job queued.'

    redirect_to ecosystems_path
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, @ecosystem)
    @ecosystem.to_model.update_attributes(comments: params[:ecosystem][:comments])
    redirect_to ecosystems_path
  end

  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_user, @ecosystem)
    output = Content::DeleteEcosystem.call(id: params[:id])
    if output.errors.empty?
      flash[:notice] = 'Ecosystem deleted.'
    else
      flash[:error] = output.errors.first.message
    end
    redirect_to ecosystems_path
  end

  def manifest
    filename = "#{FilenameSanitizer.sanitize(@ecosystem.title)}.yml"
    send_data @ecosystem.manifest.to_yaml, filename: filename
  end

  protected

  def get_ecosystem
    @ecosystem = Content::Ecosystem.find(params[:id])
  end

  def create_book_import_job(manifest_content, comments)
    manifest = Content::Manifest.from_yaml(manifest_content)
    job_id = ImportEcosystemManifest.perform_later(
      manifest: manifest,
      comments: comments
    )
    job = Jobba.find(job_id)
    cnx_id = manifest.book_cnx_ids.first
    import_url = Addressable::URI.join(manifest.archive_url, '/contents/', cnx_id).to_s
    job.save(ecosystem_import_url: import_url)
    job
  end

end
