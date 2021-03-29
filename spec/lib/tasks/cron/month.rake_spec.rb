require 'rails_helper'

RSpec.describe 'cron:month', type: :rake do
  include_context 'rake'

  it 'calls all configured routines' do
    expect(Tasks::FreezeEndedCourseTeacherPerformanceReports).to receive(:call)
    expect(Jobba).to receive(:cleanup)

    call
  end
end
