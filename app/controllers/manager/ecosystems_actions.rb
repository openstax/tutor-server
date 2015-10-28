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
    url = params[:archive_url] || @default_archive_url

    OpenStax::Cnx::V1.with_archive_url(url: url) do
      job = create_book_import_job
      import_url = OpenStax::Cnx::V1.url_for(params[:cnx_id])

      job.save(ecosystem_import_url: import_url)
      flash[:notice] = 'Ecosystem import job queued.'
    end

    redirect_to ecosystems_path
  end

  def create_book_import_job
    job_id = FetchAndImportBookAndCreateEcosystem.perform_later(
      book_cnx_id: params[:cnx_id],
      comments: params[:comments]
    )
    Lev::BackgroundJob.find(job_id)
  end

end
