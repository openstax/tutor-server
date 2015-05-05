class Exercise < Entity

  wraps Content::Models::Exercise

  exposes :url, :title, :content, :uid, :tags_with_teks

  def tags
    tag_models.collect{ |t| t.value }
  end

  def los
    tag_models.select{ |t| t.lo? }.collect{ |t| t.value }
  end

  protected

  def tag_models
    repository.exercise_tags.includes(:tag).collect{ |et| et.tag }
  end

end
