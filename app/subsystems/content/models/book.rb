class Content::Models::Book < Tutor::SubSystems::BaseModel

  wrapped_by ::Ecosystem::Strategies::Direct::Book

  belongs_to :ecosystem, subsystem: :ecosystem

  has_one :root_book_part, -> { where(parent_book_part_id: nil) },
                           class_name: '::Content::Models::BookPart'

  delegate :title, :child_book_parts, to: :root_book_part

  def chapters(eager_load = nil)
    parts = child_book_parts.eager_load(:child_book_parts)
    parts = parts.eager_load(eager_load) unless eager_load.nil?
    parts.select{ |part| part.child_book_parts.empty? }
  end

  def pages
    chapters(:pages).collect{ |ch| ch.pages }.flatten
  end

end

