require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::FakeClient, type: :external do

  subject(:fake_client) { described_class.new(OpenStax::Exercises::V1.configuration) }

  before(:each)         { fake_client.reset! }

  it 'allows searching of exercises by number' do
    fake_client.add_exercise(number: 42)
    fake_client.add_exercise(number: 36)

    expect(JSON.parse fake_client.exercises(number: 42)).to match(
      {
        total_count: 1,
        items: [{
          uuid: a_kind_of(String),
          group_uuid: a_kind_of(String),
          number: 42,
          version: 1,
          uid: "42@1",
          tags: [],
          stimulus_html: "This is fake exercise 42. " +
                         "<span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
          attachments: [ { id: "42", asset: "https://somewhere.com/something.png" } ],
          questions: [
            {
              id: "42",
              formats: ["multiple-choice", "free-response"],
              stem_html: "Select 10 N. (0)",
              answers: [
                { id: "85", content_html: "10 N", correctness: 1.0, feedback_html: 'Right!' },
                { id: "84", content_html: "1 N", correctness: 0.0, feedback_html: 'Wrong!' }
              ],
              solutions: [ content_html: 'The first one.' ]
            }
          ]
        }]
      }.deep_stringify_keys
    )
  end

  it 'allows searching of exercises by tag' do
    fake_client.add_exercise(number: -1, tags: ["billy"])
    fake_client.add_exercise(number: -2, tags: ["franky"])
    fake_client.add_exercise(number: -3, tags: ["billy"])

    expect(fake_client.exercises(tag: "billy")['total_count']).to eq 2
    expect(fake_client.exercises(tag: "billy")['items'].count).to eq 2
    expect(fake_client.exercises(tag: "franky")['total_count']).to eq 1
    expect(fake_client.exercises(tag: "franky")['items'].count).to eq 1
    expect(fake_client.exercises(tag: "tommy")['total_count']).to eq 0
    expect(fake_client.exercises(tag: "tommy")['items'].count).to eq 0

    expect(JSON.parse fake_client.exercises(tag: "franky")).to match(
      {
        total_count: 1,
        items: [{
          uuid: a_kind_of(String),
          group_uuid: a_kind_of(String),
          number: -2,
          version: 1,
          uid: "-2@1",
          tags: ["franky"],
          stimulus_html: "This is fake exercise -2. <span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
          attachments: [ {id: "-2", asset: "https://somewhere.com/something.png"} ],
          questions: [
            {
              id: "-2",
              formats: ["multiple-choice", "free-response"],
              stem_html: "Select 10 N. (0)",
              answers:[
                { id: "-3", content_html: "10 N",
                  correctness: 1.0, feedback_html: 'Right!' },
                { id: "-4", content_html: "1 N",
                  correctness: 0.0, feedback_html: 'Wrong!' }
              ],
              solutions: [ content_html: 'The first one.' ]
            }
          ]
        }]
      }.deep_stringify_keys
    )

    expect(fake_client.exercises(tag: "billy", number: -1)['total_count']).to eq 1
    expect(fake_client.exercises(tag: "billy", number: -1)['items'].count).to eq 1
  end

  it 'allows searching of exercises by version' do
    fake_client.add_exercise(number: -1)
    fake_client.add_exercise(number: -2)
    fake_client.add_exercise(number: -3)

    expect(fake_client.exercises(version: 1)['total_count']).to eq 3
    expect(fake_client.exercises(version: 1)['items'].count).to eq 3
  end

  it 'allows searching of exercises by version and id' do
    fake_client.add_exercise(number: -1)
    fake_client.add_exercise(number: -2)
    fake_client.add_exercise(number: -3)

    expect(fake_client.exercises(id: "-1@1")['total_count']).to eq 1
    expect(fake_client.exercises(id: "-1@1")['items'].count).to eq 1
    expect(fake_client.exercises(id: "-2@1")['total_count']).to eq 1
    expect(fake_client.exercises(id: "-2@1")['items'].count).to eq 1
    expect(fake_client.exercises(id: "-4@1")['total_count']).to eq 0
    expect(fake_client.exercises(id: "-4@1")['items'].count).to eq 0
  end

end
