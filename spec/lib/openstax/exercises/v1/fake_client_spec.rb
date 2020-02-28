require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::FakeClient, type: :external do
  subject(:fake_client) { described_class.new(OpenStax::Exercises::V1.configuration) }

  before(:each)         { fake_client.reset! }

  it 'allows searching of exercises by tag' do
    billy_tag = FactoryBot.create :content_tag, value: 'billy'
    billy_page = FactoryBot.create :content_page, book_location: [1, 1]
    FactoryBot.create :content_page_tag, page: billy_page, tag: billy_tag
    jean_tag = FactoryBot.create :content_tag, value: 'jean'
    jean_page = FactoryBot.create :content_page, book_location: [1, 1]
    FactoryBot.create :content_page_tag, page: jean_page, tag: jean_tag

    expect(fake_client.exercises(tag: 'billy')['total_count']).to eq 2
    expect(fake_client.exercises(tag: 'billy')['items'].count).to eq 2
    expect(fake_client.exercises(tag: 'jean')['total_count']).to eq 2
    expect(fake_client.exercises(tag: 'jean')['items'].count).to eq 2
    expect(fake_client.exercises(tag: 'michael')['total_count']).to eq 0
    expect(fake_client.exercises(tag: 'michael')['items'].count).to eq 0

    expect(fake_client.exercises(tag: 'jean')).to match(
      {
        total_count: 2,
        items: [
          {
            uuid: a_kind_of(String),
            group_uuid: a_kind_of(String),
            number: -1,
            version: 1,
            uid: '-1@1',
            tags: ['type:practice', 'k12phys', 'apbio', 'os-practice-problems', 'jean'],
            stimulus_html: "This is fake exercise -1. <span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
            attachments: [ {id: '-1', asset: 'https://somewhere.com/something.png'} ],
            questions: [
              {
                id: '-1',
                formats: ['multiple-choice', 'free-response'],
                stem_html: 'Select 10 N. (0)',
                answers:[
                  { id: '-1', content_html: '10 N',
                    correctness: 1.0, feedback_html: 'Right!' },
                  { id: '-2', content_html: '1 N',
                    correctness: 0.0, feedback_html: 'Wrong!' }
                ],
                solutions: [ content_html: 'The first one.' ]
              }
            ]
          },
          {
            uuid: a_kind_of(String),
            group_uuid: a_kind_of(String),
            number: -2,
            version: 1,
            uid: '-2@1',
            tags: ['type:conceptual-or-recall', 'k12phys', 'apbio', 'os-practice-concepts', 'jean'],
            stimulus_html: "This is fake exercise -2. <span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
            attachments: [ {id: '-2', asset: 'https://somewhere.com/something.png'} ],
            questions: [
              {
                id: '-2',
                formats: ['multiple-choice', 'free-response'],
                stem_html: 'Select 10 N. (0)',
                answers:[
                  { id: '-3', content_html: '10 N',
                    correctness: 1.0, feedback_html: 'Right!' },
                  { id: '-4', content_html: '1 N',
                    correctness: 0.0, feedback_html: 'Wrong!' }
                ],
                solutions: [ content_html: 'The first one.' ]
              }
            ]
          }
        ]
      }.deep_stringify_keys
    )
  end
end
