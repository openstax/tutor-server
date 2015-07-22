class Page < Entity

  wraps Content::Models::Page

  exposes :url, :title, :content, :chapter_section, :book_part, :is_intro?, :fragments,
          :los, :aplos

  def tags
    repository.tags.collect{ |t| t.value }
  end

end
