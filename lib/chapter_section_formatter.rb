module ChapterSectionFormatter
  def self.format(input)
    input.nil? ? nil : input.split('.').collect{|string| Integer(string)}
  end
end
