require 'rails_helper'

RSpec.describe Stats::Calculate, type: :routine do
  let!(:course) { FactoryBot.create( :course_profile_course,
      is_test: false,
      starts_at: Time.now - 1.day,
      ends_at: Time.now + 1.day,
      )
  }

  it 'runs' do
    stats = Stats::Calculate.call(date_range: (Time.now - 1.week ... Time.now)).outputs
    expect(stats.active_courses).to include course
    expect(stats.num_active_courses).to eq 1

  end

end
