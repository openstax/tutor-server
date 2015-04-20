class Exercise < Entity

  wraps Content::Models::Exercise

  instance_exposes :url, :title, :content, :exercise_tags

  def tags
    tag_models.collect{ |t| t.name }
  end

  def los
    tag_models.select{ |t| t.lo? }.collect{ |t| t.name }
  end

  protected

  def tag_models
    repository.exercise_tags.includes(:tag).collect{ |et| et.tag }
  end
  
end
