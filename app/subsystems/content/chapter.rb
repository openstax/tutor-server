class Content::Chapter < Content::BookPart
  def units
    []
  end

  def chapters
    [ self ]
  end
end
