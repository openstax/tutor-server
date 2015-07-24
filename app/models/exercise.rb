class Exercise < Entity

  wraps Content::Models::Exercise

  exposes :url, :title, :content, :uid, :los, :aplos, :tags_with_teks

  def tags
    repository.tags.collect{ |t| t.value }
  end

end
