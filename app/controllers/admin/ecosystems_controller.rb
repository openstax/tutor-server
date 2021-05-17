class Admin::EcosystemsController < Admin::BaseController
  include Manager::EcosystemsActions

  before_action :get_ecosystem, only: [ :manifest, :update, :destroy ]

  def new
    OSU::AccessPolicy.require_action_allowed!(:create, current_user, Content::Models::Ecosystem)

    if bucket_configured?
      @code_versions = content_ls.reverse
      @code_version = params[:code_version] || @code_versions.first || ''

      available_book_versions_by_uuid = Hash.new { |hash, key| hash[key] = [] }
      content_ls(@code_version)&.each do |book|
        uuid, version = book.split('@')
        available_book_versions_by_uuid[uuid] << version
      end
    else
      @code_version = params[:code_version] || ''
    end

    abl = JSON.parse(
      Faraday.get(Rails.application.secrets.openstax[:content][:abl_url]).body
    ).deep_symbolize_keys

    approved_collection_ids = Set.new(
      abl[:approved_versions].filter do |version|
        version[:min_code_version] <= @code_version
      end.map { |version| version[:collection_id] }
    )

    reading_processing_instructions_by_style = YAML.load(
      File.read 'config/reading_processing_instructions.yml'
    )

    collections_by_id = {}
    abl[:approved_books].each do |collection|
      collection_id = collection[:collection_id]
      next unless approved_collection_ids.include? collection_id
      next unless reading_processing_instructions_by_style.has_key? collection[:style]

      next if bucket_configured? && !collection[:books].all? do |book|
        available_book_versions_by_uuid.has_key? book[:uuid]
      end

      collections_by_id[collection_id] = collection
    end

    @collections = collections_by_id.map do |id, collection|
      name = collection[:books].map { |book| book[:slug].underscore.humanize }.join('; ')

      [ "#{id} - #{name}", id ]
    end
    @collection_id = params[:collection_id] || @collections.first&.second || ''
    collection = collections_by_id[@collection_id]

    style = collection[:style] unless collection.nil?
    @reading_processing_instructions = params[:reading_processing_instructions] ||
                                       reading_processing_instructions_by_style[style]&.to_yaml ||
                                       ''

    # The following line assumes only 1 book per collection
    @book_versions = available_book_versions_by_uuid[collection[:books].first[:uuid]].reverse \
      unless collection.nil?

    @book_version = params[:book_version] || @book_versions&.first || ''
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

  def content_secrets
    Rails.application.secrets.openstax[:content]
  end

  def bucket_name
    content_secrets[:bucket_name]
  end

  def bucket_configured?
    !bucket_name.blank?
  end

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

  def content_ls(code_version = nil)
    return unless bucket_configured?

    archive_path = content_secrets[:archive_path].chomp('/')

    if code_version.nil?
      prefix = "#{archive_path}/"
      delimiter = '/'
    else
      prefix = "#{archive_path}/#{code_version.chomp('/')}/contents/"
      delimiter = ':'
    end

    Aws::S3::Client.new.list_objects_v2(
      bucket: bucket_name, prefix: prefix, delimiter: delimiter
    ).flat_map(&:common_prefixes).map do |common_prefix|
      common_prefix.prefix.sub(prefix, '').chomp(delimiter)
    end
  end
end
