module Manager::EcosystemsActions

  def index
    @ecosystems = Content::ListEcosystems[]
    @incomplete_jobs = Lev::BackgroundJob.incomplete.select do |job|
      job.respond_to?(:ecosystem_import_url)
    end
  end

  def import
    @default_archive_url = OpenStax::Cnx::V1.archive_url_base
    import_ecosystem if request.post?
  end

  protected

  def import_ecosystem
    OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
      job.save(ecosystem_import_url: import_url)
      flash[:notice] = 'Ecosystem import job queued.'
    end
    redirect_to ecosystems_path
  end

  def archive_url
    if params[:archive_url].present?
      params[:archive_url]
    else
      @default_archive_url
    end
  end

  def job
    job_id = FetchAndImportBookAndCreateEcosystem.perform_later(
      book_cnx_id: params[:cnx_id],
      comments: params[:comments]
    )
    Lev::BackgroundJob.find(job_id)
  end

  def import_url
    OpenStax::Cnx::V1.url_for(params[:cnx_id])
  end

end
