class Content::Routines::CreateTags
  lev_routine

  protected

  def exec(tag_defs)
    # tag_defs should be in this format:
    # {
    #   <tag_value>: {
    #     name: "<taken from ost-standards-name>",
    #     description: "<taken from ost-standards-description>"},
    #   },
    #   <tag_value>: {
    #     name: "<taken from ost-learning-objective-def>",
    #     teks: "<teks-class>"
    #   }
    # }
    outputs[:tags] = []
    tag_defs.each do |tag_value, args|
      tag = Content::Models::Tag.find_or_initialize_by(value: tag_value.to_s)
      teks = args.delete(:teks)
      tag.update_attributes(args)
      if teks
        teks = Content::Models::Tag.find_or_initialize_by(value: teks.to_s)
        Content::Models::LoTeksTag.create(lo: tag, teks: teks)
      end
      outputs[:tags] << tag
    end
  end
end
