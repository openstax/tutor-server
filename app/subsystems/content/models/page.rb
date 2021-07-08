class Content::Models::Page < IndestructibleRecord
  POOL_TYPES = [
    :all,
    :reading_context,
    :reading_dynamic,
    :homework_core,
    :homework_dynamic,
    :practice_widget
  ]
  EXERCISE_ID_FIELDS = POOL_TYPES.map { |type| "#{type}_exercise_ids".to_sym }
  acts_as_resource

  auto_uuid :tutor_uuid

  json_serialize :fragments, OpenStax::Content::Fragment, array: true
  json_serialize :snap_labs, Hash, array: true
  json_serialize :book_location, Integer, array: true

  belongs_to :book, inverse_of: :pages
  has_one :ecosystem, through: :book

  has_many :exercises, dependent: :destroy, inverse_of: :page
  has_many :page_tags, dependent: :destroy, inverse_of: :page
  has_many :tags, through: :page_tags

  has_many :same_uuid_pages, class_name: 'Page', primary_key: 'uuid', foreign_key: 'uuid'

  has_many :task_steps, subsystem: :tasks, dependent: :destroy, inverse_of: :page

  has_many :notes, subsystem: :content, dependent: :destroy, inverse_of: :page

  validates :title, presence: true
  validates :uuid, presence: true
  validates :url, presence: true

  scope :with_exercises, -> { where('CARDINALITY("content_pages"."all_exercise_ids") > 0') }

  def self.pool_types
    [
      :all,
      :reading_context,
      :reading_dynamic,
      :homework_core,
      :homework_dynamic,
      :practice_widget
    ]
  end

  def type
    'Page'
  end

  def related_content
    {
      uuid: uuid,
      page_id: id,
      title: title,
      book_location: book_location
    }
  end

  def ox_id
    "#{uuid}@#{version}"
  end

  def los
    tags.filter(&:lo?)
  end

  def aplos
    tags.filter(&:aplo?)
  end

  def cnxmods
    tags.filter(&:cnxmod?)
  end

  def cache_fragments_and_snap_labs
    return if id.nil? || fragment_splitter.nil?

    self.fragments = fragment_splitter.split_into_fragments(parser.root).map(&:to_yaml)
    self.snap_labs = parser.snap_lab_nodes.map do |snap_lab_node|
      {
        id: snap_lab_node.attr('id'),
        title: parser.snap_lab_title(snap_lab_node),
        fragments: fragment_splitter.split_into_fragments(snap_lab_node, 'snap-lab').map(&:to_yaml)
      }
    end
  end

  def fragments
    @fragments ||= (super || []).map { |yaml| YAML.load(yaml) }
  end

  def fragments=(fragments)
    @fragments = nil
    super
  end

  def snap_labs
    @snap_labs ||= (super || []).map do |snap_lab|
      sl = snap_lab.symbolize_keys
      sl.merge fragments: sl[:fragments].map { |yaml| YAML.load(yaml) }
    end
  end

  def snap_labs=(snap_labs)
    @snap_labs = nil
    super
  end


  def snap_labs_with_page_id
    snap_labs.map { |snap_lab| snap_lab.merge(page_id: id) }
  end

  def context_for_feature_ids(feature_ids)
    @context_for_feature_ids ||= {}
    return @context_for_feature_ids[feature_ids] if @context_for_feature_ids.has_key?(feature_ids)

    doc = Nokogiri::HTML(content)
    feature_node = parser_class.feature_node(doc, feature_ids)
    @context_for_feature_ids[feature_ids] = feature_node.try(:to_html)
  end

  def reference_view_url(book: self.book)
    raise('Unpersisted Page') if id.nil?

    "#{book.reference_view_url}/page/#{id}"
  end

  def resolve_links!
    node = Nokogiri::HTML content

    # Absolutize embed urls
    node.css('[src]').each do |link|
      src = link.attributes['src']
      src.value = resolve_link src.value
    end

    # Absolutize link urls
    node.css('[href]').each do |link|
      href = link.attributes['href']
      href.value = resolve_link href.value
    end

    self.content = node.to_html
  end

  def resolve_link(link)
    begin
      uri = Addressable::URI.parse link
    rescue InvalidURIError
      Rails.logger.warn { "Invalid url: \"#{link}\" in page: #{url}" }
      return link
    end

    if uri.absolute?
      # Force absolute URLs to be https
      uri.scheme = 'https'
      return uri.to_s
    end

    # Keep anchor-only URLs (links to the same page) relative
    return link if uri.path.blank?

    if uri.path.starts_with?('./')
      # Content link
      if uri.path.starts_with?("./#{book.uuid}@#{book.version}:")
        # Same book link
        if uri.path.starts_with?("./#{book.uuid}@#{book.version}:#{uuid}")
          # Link to the same page
          # This should just be a relative link
          uri.path = ''
          uri.to_s
        else
          # Link to another page in the same book
          # Send to reference view
          page_uuid = uri.path.split(':', 2).last.split('@', 2).first.split('.', 2).first
          page = if book.pages.loaded?
            book.pages.detect { |page| page.uuid == page_uuid }
          else
            book.pages.find_by uuid: page_uuid
          end

          if page.nil?
            Rails.logger.warn do
              "Page #{url} contains a link to #{link}, a page in the same book which was not found"
            end

            return link
          end

          uri.path = page.reference_view_url
          uri.to_s
        end
      else
        # Link to a different book
        # The user might not have access to the book in Tutor, so it's safer to send them to REX
        book.archive.webview_uri_for(uri).to_s
      end
    else
      # Resource link or other unknown relative link
      # Delegate to OpenStax::Content::Archive
      book.archive.url_for link
    end
  end

  protected

  def parser_class
    OpenStax::Content::Page
  end

  def parser
    @parser ||= parser_class.new(uuid: uuid, url: url, title: title, content: content)
  end

  def fragment_splitter
    return if book.nil?

    @fragment_splitter ||= OpenStax::Content::FragmentSplitter.new(
      book.reading_processing_instructions, reference_view_url
    )
  end
end

# Compatibility: Many existing pages have serialized fragments saved as OpenStax::Cnx::V1::Fragment
module OpenStax::Cnx
  V1 = ::OpenStax::Content
end
