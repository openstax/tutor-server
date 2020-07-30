class CourseProfile::Models::Cache < ApplicationRecord
  belongs_to :course, inverse_of: :cache
end
