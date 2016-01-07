module Manager::EcosystemsActions

  def index
    @ecosystems = Content::ListEcosystems[]
    @incomplete_jobs = Lev::BackgroundJob.incomplete.select do |job|
      job.respond_to?(:ecosystem_import_url)
    end
    @failed_jobs = Lev::BackgroundJob.failed.select do |job|
      job.respond_to?(:ecosystem_import_url)
    end
  end

  def update
    ecosystem = Content::Ecosystem.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, ecosystem)
    ecosystem.to_model.update_attributes(comments: params[:ecosystem][:comments])
    redirect_to ecosystems_path
  end

  def import
    @default_archive_url = OpenStax::Cnx::V1.archive_url_base
    import_ecosystem if request.post?
  end

  def destroy
    ecosystem = Content::Ecosystem.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_user, ecosystem)
    output = Content::DeleteEcosystem.call(id: params[:id])
    if output.errors.empty?
      flash[:notice] = 'Ecosystem deleted.'
    else
      flash[:error] = output.errors.first.message
    end
    redirect_to ecosystems_path
  end

  protected

  def archive_url
    params[:archive_url].present? ? params[:archive_url] : @default_archive_url
  end

  def import_ecosystem
    create_book_import_job
    flash[:notice] = 'Ecosystem import job queued.'

    redirect_to ecosystems_path
  end

  def create_book_import_job
    job_id = FetchAndImportBookAndCreateEcosystem.perform_later(
      archive_url: archive_url,
      book_cnx_id: params[:cnx_id],
      comments: params[:comments]
    )
    job = Lev::BackgroundJob.find(job_id)
    import_url = OpenStax::Cnx::V1.url_for(params[:cnx_id])
    job.save(ecosystem_import_url: import_url)
    job
  end

end
