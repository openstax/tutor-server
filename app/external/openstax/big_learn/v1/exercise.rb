class OpenStax::BigLearn::V1::Exercise

  attr_reader :uid, :tags

  def initialize(uid, *tags)
    if tags.empty?
      raise IllegalArgument, 'Must specify at least one tag'
    end

    tags = tags.collect{|tag| tag.to_s}

    @uid = uid
    @tags = tags
  end


end
