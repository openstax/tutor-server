module FilenameSanitizer
  def self.sanitize(filename)
    return nil if filename.nil?

    filename.gsub(/[^\w.-]/, '_').gsub(/_{2,}/, '_')
  end
end
