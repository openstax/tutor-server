module Lms::Queries

  # At some point this could handle apps installed at the TC level
  # if it doesn't find anything, find Context from Course,
  # get TC from Context, find App by TC
  def self.app_for_course(course)
    raise ActiveRecord::RecordNotFound unless course.lms_context

    course.lms_context.app
  end

  def self.app_for_key(key)
    [Lms::WilloLabs, Lms::Models::App].each do |model|
      app = model.find_by(key: key)
      return app if app
    end
    nil
  end

end
