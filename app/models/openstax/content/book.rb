class OpenStax::Content::Book
  def initialize(
    archive_version:, uuid: nil, version: nil, hash: nil, title: nil, tree: nil, root_book_part: nil
  )
    @uuid            = uuid || (hash || {})['id']
    raise ArgumentError, 'Either uuid or hash with id key is required' if @uuid.nil?

    @version         = version || (hash || {})['version']
    raise ArgumentError, 'Either version or hash with version key is required' if @version.nil?

    @archive_version = archive_version
    @hash            = hash
    @title           = title
    @tree            = tree
    @root_book_part  = root_book_part
  end

  attr_reader :archive_version, :uuid, :version

  def archive
    @archive ||= OpenStax::Content::Archive.new archive_version
  end

  def url
    @url ||= archive.url_for "#{uuid}@#{version}"
  end

  def url_fragment
    @url_fragment ||= url.chomp('.json')
  end

  def baked
    @baked ||= hash['baked']
  end

  def collated
    @collated ||= hash.fetch('collated', false)
  end

  def hash
    @hash ||= archive.json url
  end

  def uuid
    @uuid ||= hash.fetch('id')
  end

  def short_id
    @short_id ||= hash['shortId']
  end

  def version
    @version ||= hash.fetch('version')
  end

  def title
    @title ||= hash.fetch('title')
  end

  def tree
    @tree ||= hash.fetch('tree')
  end

  def root_book_part
    @root_book_part ||= OpenStax::Content::BookPart.new(hash: tree, is_root: true, book: self)
  end
end
