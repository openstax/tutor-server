class Exercise < Entity
  self.repository_class = Content::Models::Exercise

  exposes :find, :url, :title, :content
end
