module Manager::EcosystemsActions

  def index
    @ecosystems = Content::ListEcosystems[]
    Content::Models::EcosystemJob.update_status
    @incomplete_jobs = Content::Models::EcosystemJob.incomplete.collect do |job|
      Lev::BackgroundJob.find(job.import_job_uuid)
    end
  end

  def import
    @default_archive_url = OpenStax::Cnx::V1.archive_url_base
    import_ecosystem if request.post?
  end

  protected

  def import_ecosystem
    archive_url = params[:archive_url].present? ? params[:archive_url] : @default_archive_url

    OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
      job_id = FetchAndImportBookAndCreateEcosystem.perform_later(book_cnx_id: params[:cnx_id])
      job = Lev::BackgroundJob.find(job_id)
      import_url = OpenStax::Cnx::V1.url_for(params[:cnx_id])
      job.save(ecosystem_import_url: import_url)
      Content::Models::EcosystemJob.create(import_job_uuid: job_id)
      flash[:notice] = 'Ecosystem import job queued.'
    end
    redirect_to ecosystems_path
  end

end
