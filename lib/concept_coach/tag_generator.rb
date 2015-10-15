module ConceptCoach
  class TagGenerator
    def initialize(cc_string)
      @cc_string = cc_string
    end

    def generate(book_location)
      return [] if @cc_string.blank?

      chapter_string = "#{@cc_string}-ch#{"%02d" % book_location.first}"
      section_string = "#{chapter_string}-s#{"%02d" % book_location.last}"

      [ { value: section_string, type: :cc } ]
    end
  end
end
