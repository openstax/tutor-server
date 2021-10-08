require 'rails_helper'

RSpec.describe Api::V1::PerformanceReport::Representer, type: :representer do
  let(:period)             { FactoryBot.create(:course_membership_period) }
  let(:last_worked_at)     { Time.current                                 }
  let(:type)               { 'homework'                                   }
  let(:due_at)             { Time.current + 1.week                        }
  let(:api_last_worked_at) { DateTimeUtilities.to_api_s(last_worked_at)   }
  let(:api_due_at)         { DateTimeUtilities.to_api_s(due_at)           }

  let(:report) do
    {
      period: period,
      data_headings: [
        {
          title: 'title',
          plan_id: 2,
          due_at: Time.current + 1.week,
          average: 75.0
        }
      ],
      students: [
        {
          name: 'Student One',
          role: 2,
          student_identifier: '1234',
          data: [
            {
              status: 'completed',
              type: type,
              id: 5,
              last_worked_at: last_worked_at,
              due_at: due_at,
              actual_and_placeholder_exercise_count: 6,
              completed_exercise_count: 6,
              correct_exercise_count: 6,
              recovered_exercise_count: 0,
              is_provisional_score: false
            }
          ]
        }
      ]
    }
  end

  let(:representation)   { described_class.new([Hashie::Mash.new(report)]).to_hash }
  let(:representation_1) { representation.first }

  it 'includes the period_id, data_headings and students fields' do
    expect(representation_1['period_id']).to eq period.id.to_s
    expect(representation_1['data_headings']).to be_a(Array)
    expect(representation_1['students']).to be_a(Array)
  end

  context 'students' do
    it "represents a student's information" do
      expect(representation_1['students'][0]).to match(
        'name' => 'Student One',
        'role' => 2,
        'student_identifier'=>'1234',
        'data' => an_instance_of(Array)
      )
    end

    context 'data' do
      it 'includes the type, due_at and is_provisional_score fields' do
        expect(representation_1['students'].first['data'].first).to include(
          'type' => type,
          'due_at' => api_due_at,
          'is_provisional_score' => false
        )
      end

      it 'handles missing tasks well' do
        report[:students][0][:data] = []
        expect(representation_1['students'].first['data']).to eq []
      end
    end
  end
end
