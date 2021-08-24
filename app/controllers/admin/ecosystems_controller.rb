class Admin::EcosystemsController < Admin::BaseController
  include Manager::EcosystemsActions

  before_action :get_ecosystem, only: [ :manifest, :update, :destroy ]

  def new
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Models::Ecosystem)

    if s3.bucket_configured?
      @archive_versions = s3.ls.reverse
      @archive_version = params[:archive_version] || @archive_versions.first || ''

      available_versions_by_uuid = Hash.new { |hash, key| hash[key] = [] }
      s3.ls(@archive_version).each do |book|
        uuid, version = book.split('@')
        available_versions_by_uuid[uuid] << version
      end
    else
      @archive_version = params[:archive_version] || ''
    end

    approved_versions_by_collection_id = Hash.new { |hash, key| hash[key] = [] }
    abl.approved_versions.filter do |version|
      version[:min_code_version] <= @archive_version
    end.each do |version|
      approved_versions_by_collection_id[version[:collection_id]] << \
        version[:content_version].sub(/\A1./, '')
    end

    collections_by_id = {}
    versions_by_collection_id = {}
    abl.approved_books.each do |collection|
      collection_id = collection[:collection_id]
      next unless approved_versions_by_collection_id.has_key? collection_id
      next unless reading_processing_instructions_by_style.has_key? collection[:style]

      books = collection[:books]
      next if s3.bucket_configured? && !books.all? do |book|
        available_versions_by_uuid.has_key? book[:uuid]
      end

      # Books inside the same collection must use the same versions otherwise
      # the structure of approved_versions would need to change
      versions = available_versions_by_uuid[books.first[:uuid]] &
                 approved_versions_by_collection_id[collection_id]

      collections_by_id[collection_id] = collection
      versions_by_collection_id[collection_id] = versions.sort_by(&:to_f).reverse
    end

    @collections = collections_by_id.map do |id, collection|
      name = collection[:books].map { |book| book[:slug].underscore.humanize }.join('; ')

      [ "#{name} - #{id}", id ]
    end.sort
    @collection_id = params[:collection_id] || @collections.first&.second || ''
    collection = collections_by_id[@collection_id]

    style = collection[:style] unless collection.nil?
    @reading_processing_instructions = params[:reading_processing_instructions] ||
                                       reading_processing_instructions_by_style[style]&.to_yaml ||
                                       ''

    @book_versions = versions_by_collection_id[@collection_id]

    @book_version = params[:book_version] || @book_versions&.first || ''
  end

  def create
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Models::Ecosystem)

    collection = abl.approved_books.detect do |collection|
      collection[:collection_id] == params[:collection_id]
    end
    return head(:not_found) if collection.nil?

    FetchAndImportBookAndCreateEcosystem.perform_later(
      archive_version: params[:archive_version],
      book_uuid: collection[:books].first[:uuid],
      book_version: params[:book_version],
      reading_processing_instructions: YAML.safe_load(params[:reading_processing_instructions]),
      comments: params[:comments]
    )

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

  def abl
    @abl ||= OpenStax::Content::Abl.new
  end

  def s3
    @s3 ||= OpenStax::Content::S3.new
  end

  def ecosystems_path
    admin_ecosystems_path
  end

  def reading_processing_instructions_by_style
    @reading_processing_instructions_by_style ||= YAML.load_file(
      'config/reading_processing_instructions.yml'
    )
  end
end
