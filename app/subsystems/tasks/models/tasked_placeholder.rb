class Tasks::Models::TaskedPlaceholder < Tutor::SubSystems::BaseModel
  acts_as_tasked

  def title
    nil
  end

  def url
    nil
  end

  def content
    nil
  end
end
