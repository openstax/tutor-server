require 'rails_helper'
require_relative 'course_representer_shared_examples'

RSpec.describe Api::V1::CourseRepresenter, type: :representer do
  include_examples 'api_v1_course_representer'
end
