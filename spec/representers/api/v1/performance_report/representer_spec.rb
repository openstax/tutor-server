require 'rails_helper'

RSpec.describe Api::V1::PerformanceReport::Representer, type: :representer do

  let(:period)               { FactoryBot.create(:course_membership_period) }
  let(:last_worked_at)       { Time.current                                  }
  let(:due_at)               { Time.current + 1.week                         }
  let(:accepted_late_at)     { Time.current + 2.weeks}
  let(:api_last_worked_at)   { DateTimeUtilities.to_api_s(last_worked_at)    }
  let(:api_due_at)           { DateTimeUtilities.to_api_s(due_at)            }
  let(:api_accepted_late_at) { DateTimeUtilities.to_api_s(accepted_late_at)}

  let(:report) do
    {
      period: period,
      data_headings: [
        {
          title: "title",
          plan_id: 2,
          due_at: Time.current + 1.week,
          average: 75.0
        }
      ],
      students: [
        {
          name: "Student One",
          role: 2,
          student_identifier: '1234',
          data: [
            {
              status: "completed",
              type: "homework",
              id: 5,
              last_worked_at: last_worked_at,
              accepted_late_at: accepted_late_at,
              due_at: due_at,
              actual_and_placeholder_exercise_count: 6,
              completed_exercise_count: 6,
              correct_exercise_count: 6,
              recovered_exercise_count: 0
            }
          ]
        }
      ]
    }
  end

  let(:representation) { described_class.new([Hashie::Mash.new(report)]).to_hash }

  it 'includes the due_at, last_worked_at properties for student data' do
    task_data = representation.first['students'].first['data'].first
    expect(task_data).to include(
      'last_worked_at' => api_last_worked_at,
      'due_at' => api_due_at,
      'accepted_late_at' => api_accepted_late_at
    )
  end

  it 'represents a students information' do
    expect(representation.first['students'][0]).to match(
      'name' => 'Student One',
      'role' => 2,
      'student_identifier'=>'1234',
      'data' => an_instance_of(Array)
    )
  end

  it 'handles missing tasks well' do
    report[:students][0][:data] = []
    representation = described_class.new([Hashie::Mash.new(report)]).to_hash
    data = representation.first['students'].first['data']
    expect(data).to eq []
  end
end
