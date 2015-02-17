require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::FakeClient do

  let(:fake_client) {OpenStax::Exercises::V1.fake_client}
  before(:each) {fake_client.reset!}

  it 'allows adding of exercises' do
    expect{fake_client.add_exercise}.to change{fake_client.exercises_array.count}.by(1)
  end

  it 'allows searching of exercises by number' do
    fake_client.add_exercise(number: 42)
    fake_client.add_exercise(number: 36)

    expect(fake_client.exercises(number: 42)).to eq(
      [{
        stimulus: "This is fake exercise 42.  <span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
        questions: [
          {
            id: "1",
            format: "multiple-choice",
            stem: "Select the answer that makes the most sense.",
            answers:[
              {id: "2", content: "10 N"},
              {id: "3", content: "1 N"}
            ]
          }
        ]
      }]
    )
  end

  it 'allows searching of exercises by tag' do
    fake_client.add_exercise(tags: ["billy"])
    fake_client.add_exercise(tags: ["franky"])
    fake_client.add_exercise(tags: ["billy"])

    expect(fake_client.exercises(tag: "billy").count).to eq 2
    expect(fake_client.exercises(tag: "franky").count).to eq 1
    expect(fake_client.exercises(tag: "tommy").count).to eq 0

    expect(fake_client.exercises(tag: "franky")).to eq(
      [{
        stimulus: "This is fake exercise 2.  <span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
        questions: [
          {
            id: "4",
            format: "multiple-choice",
            stem: "Select the answer that makes the most sense.",
            answers:[
              {id: "5", content: "10 N"},
              {id: "6", content: "1 N"}
            ]
          }
        ]
      }]
    )

    expect(fake_client.exercises(tag: "billy", number: 1).count).to eq 1
  end

  it 'allows searching of exercises by version' do
    fake_client.add_exercise
    fake_client.add_exercise
    fake_client.add_exercise

    expect(fake_client.exercises(version: 1).count).to eq 3
  end

  it 'allows searching of exercises by version and id' do
    fake_client.add_exercise
    fake_client.add_exercise
    fake_client.add_exercise

    expect(fake_client.exercises(id: "e1v1").count).to eq 1
    expect(fake_client.exercises(id: "e2v1").count).to eq 1
    expect(fake_client.exercises(id: "e4v1").count).to eq 0
  end

end



