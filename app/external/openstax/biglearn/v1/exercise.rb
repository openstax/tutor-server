class OpenStax::Biglearn::V1::Exercise

  attr_reader :url, :tags

  def initialize(url, *tags)
    if tags.empty?
      raise IllegalArgument, 'Must specify at least one tag'
    end

    tags = tags.collect{|tag| tag.to_s}

    @url = url
    @tags = tags
  end


end
