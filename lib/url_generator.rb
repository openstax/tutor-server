module Routing
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  included do
    def default_url_options
      ActionMailer::Base.default_url_options
    end
  end
end

class UrlGenerator
  include Routing

  def self.teach_course_url(token)
    new.teach_course_url(token, "DO_NOT_GIVE_TO_STUDENTS")
  end
end
