class Exercise < Entity

  wraps Content::Models::Exercise

  exposes :url, :title, :content, :uid, :tags_with_teks

  def tags
    repository.tags.collect{ |t| t.value }
  end

  def los
    repository.tags.select{ |t| t.lo? }.collect{ |t| t.value }
  end

end
