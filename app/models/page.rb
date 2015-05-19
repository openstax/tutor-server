class Page < Entity

  wraps Content::Models::Page

  exposes :url, :title, :content, :chapter_section, :book_part, :is_intro?, :fragments

  def tags
    tag_models.collect{ |t| t.value }
  end

  def los
    tag_models.select{ |t| t.lo? }.collect{ |t| t.value }
  end

  protected

  def tag_models
    repository.page_tags.includes(:tag).collect{ |et| et.tag }
  end

end
