module Lms::Queries

  # all contexts will share the same app, but a course may not
  # have any contexts if it's never been launched into
  # we only want to reveal the app if there's at least one context
  def self.app_for_course(course)
    course.lms_contexts.first!.app
  end

  def self.app_for_key(key)
    [Lms::WilloLabs, Lms::Models::App].each do |model|
      app = model.find_by(key: key)
      return app if app
    end
    nil
  end

end
