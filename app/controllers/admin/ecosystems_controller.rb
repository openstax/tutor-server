class Admin::EcosystemsController < Admin::BaseController
  def index
    @ecosystems = Content::ListEcosystems[]
  end

  def import
    @default_archive_url = OpenStax::Cnx::V1.archive_url_base
    import_ecosystem if request.post?
  end

  protected

  def import_ecosystem
    archive_url = params[:archive_url].present? ? params[:archive_url] : @default_archive_url

    OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
      ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: params[:cnx_id],
        tag_generator: ConceptCoach::TagGenerator.new(params[:cc_tag])
      ]
      flash[:notice] = "Ecosystem \"#{ecosystem.title}\" imported."
    end
    redirect_to admin_ecosystems_path
  end
end
