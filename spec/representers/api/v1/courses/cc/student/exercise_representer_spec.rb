require 'rails_helper'

RSpec.describe Api::V1::Courses::Cc::Student::ExerciseRepresenter, type: :representer do
  let(:exercise)           {
    Hashie::Mash.new({
      id: 42,
      is_completed: true,
      is_correct: false
    })
  }

  let(:representation) { described_class.new(exercise).as_json }

  it 'represents exercise stats' do
    expect(representation['id']).to eq '42'
    expect(representation['is_completed']).to eq true
    expect(representation['is_correct']).to eq false
  end
end
