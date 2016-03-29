module FilenameSanitizer
  def self.sanitize(filename)
    filename.gsub(/[^0-9A-Za-z.-]/, '_')
  end
end
