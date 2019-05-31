class Content::SearchTags
  lev_routine express_output: :tags

  protected

  def exec(tag_value:)
    tg = Content::Models::Tag.arel_table
    outputs.tags = Content::Models::Tag.where(tg[:value].matches(tag_value))
                                       .order(:value, :created_at)
  end
end
