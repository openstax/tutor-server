class Admin::EcosystemsController < Admin::BaseController
  include Manager::EcosystemsActions

  before_action :get_ecosystem, only: [ :manifest, :update, :destroy ]

  def new
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Models::Ecosystem)

    if s3.bucket_configured?
      @pipeline_versions = s3.ls.reverse
      @pipeline_version = params[:pipeline_version] || @pipeline_versions.first || ''

      available_versions_by_uuid = Hash.new { |hash, key| hash[key] = [] }
      s3.ls(@pipeline_version).each do |book|
        uuid, version = book.split('@')
        available_versions_by_uuid[uuid] << version
      end
    else
      @pipeline_version = params[:pipeline_version] || ''
    end

    collections_by_repository_name = abl.approved_books.filter do |collection|
      collection[:versions].any? do |version|
        books = version[:commit_metadata][:books]
        !s3.bucket_configured? || books.all? do |book|
          available_versions = available_versions_by_uuid[book[:uuid]] || []

          available_versions.include?(version[:commit_sha].first(7)) &&
          reading_processing_instructions_by_style.has_key?(book[:style])
        end
      end
    end.index_by do |collection|
      collection[:repository_name]
    end

    @collections = collections_by_repository_name.map do |repository_name, collection|
      latest_version = collection[:versions].sort_by { |version| version[:committed_at] }.last
      name = latest_version[:commit_metadata][:books].map do |book|
        book[:slug].underscore.humanize
      end.join('; ')

      [ "#{name} - #{repository_name}", repository_name ]
    end.sort
    @repository_name = params[:repository_name] || @collections.first&.second || ''

    collection = collections_by_repository_name[@repository_name]
    if collection.nil?
      style = nil
      @content_versions = []
    else
      versions = collection[:versions].filter do |version|
        books = version[:commit_metadata][:books]
        !s3.bucket_configured? || books.all? do |book|
          available_versions = available_versions_by_uuid[book[:uuid]] || []

          available_versions.include?(version[:commit_sha].first(7)) &&
          reading_processing_instructions_by_style.has_key?(book[:style])
        end
      end.sort_by { |version| version[:committed_at] }.reverse
      latest_version = versions.first
      style = latest_version[:commit_metadata][:books].first[:style]
      @content_versions = versions.map { |version| version[:commit_sha].first(7) } || []
    end

    @reading_processing_instructions = params[:reading_processing_instructions] ||
                                       reading_processing_instructions_by_style[style]&.to_yaml ||
                                       ''

    @content_version = params[:content_version] || @content_versions&.first || ''
  end

  def create
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Models::Ecosystem)

    collection = abl.approved_books.detect do |collection|
      collection[:repository_name] == params[:repository_name]
    end
    return head(:not_found) if collection.nil?

    FetchAndImportBookAndCreateEcosystem.perform_later(
      archive_version: params[:pipeline_version],
      book_uuid: collection[:books].first[:uuid],
      book_version: params[:content_version],
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
