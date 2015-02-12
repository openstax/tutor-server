require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::FakeClient do

  let(:fake_client) {OpenStax::Exercises::V1.fake_client}

  it 'allows adding of exercises' do
    expect{fake_client.add_exercise}.to change{fake_client.exercises_array.count}.by(1)
  end

  it 'allows searching of exercises by number' do
    fake_client.add_exercise(number: 42)
    expect(fake_client.exercises(number: 42).count).to eq 1
  end

end



