class Content::Page < Content::BookPart
  def units
    []
  end

  def chapters
    []
  end

  def pages
    [ self ]
  end
end
