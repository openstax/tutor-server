require 'rails_helper'

RSpec.describe CourseProfile::Models::TimeZone, type: :model do
  it { is_expected.to validate_inclusion_of(:name)
                        .in_array(ActiveSupport::TimeZone.all.map(&:name)) }
end
