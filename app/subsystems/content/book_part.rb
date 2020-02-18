# These records are not ActiveRecord::Base, so they are not persisted in the DB
# Instead, they are initialized from the book's tree field
class Content::BookPart
  attr_reader :tree

  def initialize(tree)
    @tree = tree.deep_symbolize_keys
  end

  (
    [ :id, :type, :uuid, :version, :short_id, :tutor_uuid, :title, :book_location ] +
    Content::Models::Page::EXERCISE_ID_FIELDS
  ).each do |key|
    define_method(key) { tree[key] }
  end

  def cnx_id
    "#{uuid}@#{version}"
  end

  def unmapped_ids
    tree[:unmapped_ids] || [ id ]
  end

  def unmapped_tutor_uuids
    tree[:unmapped_tutor_uuids] || [ tutor_uuid ]
  end

  def children
    @children ||= tree.fetch(:children, []).map do |child|
      case child[:type].downcase
      when 'unit'
        Content::Unit.new(child)
      when 'chapter'
        Content::Chapter.new(child)
      when 'page'
        Content::Page.new(child)
      else
        raise "Unknown BookPart type: #{child[:type]}"
      end
    end
  end

  def units
    children.flat_map(&:units)
  end

  def chapters
    children.flat_map(&:chapters)
  end

  def pages
    children.flat_map(&:pages)
  end
end
