class Content::SearchTags
  lev_routine outputs: { tags: :_self }

  protected

  def exec(tag_value:)
    set(tags: Content::Models::Tag.where{ value.like tag_value }
                                  .order{ [value, created_at] })
  end
end
