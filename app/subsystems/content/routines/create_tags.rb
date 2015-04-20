class Content::Routines::CreateTags
  lev_routine

  protected

  def exec(tag_defs)
    # tag_defs should be in this format:
    # {
    #   <tag_value>: {
    #     name: "<taken from ost-standards-name>",
    #     description: "<taken from ost-standards-description>"}
    # }
    outputs[:tags] = []
    tag_defs.each do |tag_value, args|
      tag = Content::Models::Tag.find_or_initialize_by(value: tag_value.to_s)
      tag.update_attributes(args)
      outputs[:tags] << tag
    end
  end
end
