class Content::SearchTags
  lev_routine express_output: :tags

  protected

  def exec(tag_value:)
    outputs[:tags] = Content::Models::Tag.where{ value.like tag_value }
                                         .order{ [value, created_at] }
  end
end
