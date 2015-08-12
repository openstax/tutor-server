require 'rails_helper'

RSpec.describe Api::V1::PerformanceReportRepresenter do
  it 'includes the due_at, last_worked_at properties for student data' do
    period = FactoryGirl.create(:period)
    last_worked_at = Time.current
    due_at = Time.current + 1.week
    api_last_worked_at = DateTimeUtilities.to_api_s(last_worked_at)
    api_due_at = DateTimeUtilities.to_api_s(due_at)

    report = { period: period,
               data_headings: [{ title: "title",
                                 plan_id: 2,
                                 due_at: Time.current + 1.week,
                                 average: 75.0 }],
               students: [{ name: "Student One",
                            role: 2,
                            data: [{ status: "completed",
                                     type: "homework",
                                     id: 5,
                                     last_worked_at: last_worked_at,
                                     due_at: due_at,
                                     actual_and_placeholder_exercise_count: 6,
                                     correct_exercise_count: 6,
                                     recovered_exercise_count: 0 }] }] }

    representation = described_class.new([Hashie::Mash.new(report)]).to_hash

    task_data = representation.first['students'].first['data'].first
    expect(task_data).to include('last_worked_at' => api_last_worked_at,
                                 'due_at' => api_due_at)
  end
end
