module Lms
  class OutcomeResponse

    def initialize(response)
      @xml = Nokogiri::XML.parse(response.body)
    end

    def code_major
      @code_major ||= @xml.at_css('imsx_POXHeader imsx_statusInfo imsx_codeMajor')&.content || 'failure'
    end

    def description
      @description ||= @xml.at_css('imsx_POXHeader imsx_statusInfo imsx_description')&.content
    end

  end
end
