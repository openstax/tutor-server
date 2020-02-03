class Admin::EcosystemsController < Admin::BaseController
  include Manager::EcosystemsActions

  before_action :get_ecosystem, only: [ :manifest, :update, :destroy ]

  def new
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Models::Ecosystem)
  end

  def create
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Models::Ecosystem)
    ecosystem_params = params[:ecosystem] || {}
    manifest_content = ecosystem_params[:manifest].respond_to?(:read) ? \
                         ecosystem_params[:manifest].read : ecosystem_params[:manifest].to_s

    manifest = Content::Manifest.from_yaml(manifest_content)

    manifest.update_books! if ecosystem_params[:books] == 'update'

    case ecosystem_params[:exercises]
    when 'update'
      manifest.update_exercises!
    when 'discard'
      manifest.discard_exercises!
    end

    if !manifest.valid?
      flash[:error] = manifest.errors.join('; ')
      redirect_to ecosystems_path
      return
    elsif manifest.books.size != 1
      flash[:error] = 'Only 1 book per ecosystem is currently supported'
      redirect_to ecosystems_path
      return
    end

    create_book_import_job(manifest, ecosystem_params[:comments])

    redirect_to ecosystems_path, notice: 'Ecosystem import job queued.'
  end

  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_user, @ecosystem)
    @ecosystem.update_attributes(comments: params[:ecosystem][:comments])
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

  protected

  def ecosystems_path
    admin_ecosystems_path
  end

  def create_book_import_job(manifest, comments)
    job_id = ImportEcosystemManifest.perform_later(manifest: manifest, comments: comments)
    job = Jobba.find(job_id)
    book = manifest.books.first
    archive_url = book.archive_url || OpenStax::Cnx::V1.archive_url_base
    import_url = Addressable::URI.join(archive_url, '/contents/', book.cnx_id).to_s
    job.save(ecosystem_import_url: import_url)
    job
  end
end
