module Lms::Queries

  def self.app_for_course(course)
    Lms::Models::App.find_by!(owner: course)

    # Later, change this to handle apps installed at the TC level
    # if above doesn't find anything, find Context from Course,
    # get TC from Context, find App by TC
  end

end
