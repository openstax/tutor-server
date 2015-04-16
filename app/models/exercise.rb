class Exercise < Entity
  wraps Content::Models::Exercise

  exposes :find, :url, :title, :content

  def tags
    repository.exercise_tags.includes(:tag).collect{|et| et.tag.name}
  end
end
