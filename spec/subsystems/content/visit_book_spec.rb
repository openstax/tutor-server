require 'rails_helper'

RSpec.describe Content::VisitBook, :type => :routine do

  around(:each) do |example|
    OpenStax::Exercises::V1.use_fake_client
    OpenStax::Exercises::V1.fake_client.reset!
    example.run
    OpenStax::Exercises::V1.fake_client.reset!
  end

  let!(:root_book_part) { FactoryGirl.create(:content_book_part, :standard_contents_1) }

  it "should get the TOC with the TOC option" do
    toc = Content::VisitBook[book: root_book_part.book, visitor_names: :toc]

    expect(toc).to eq([{
      'id' => 2,
      'title' => 'unit 1',
      'type' => 'part',
      'children' => [
        {
          'id' => 3,
          'title' => 'chapter 1',
          'type' => 'part',
          'children' => [
            {
              'id' => 1,
              'title' => 'first page',
              'type' => 'page',
              'path' => '1.1'
            },
            {
              'id' => 2,
              'title' => 'second page',
              'type' => 'page',
              'path' => '1.2'
            }
          ]
        },
        {
          'id' => 4,
          'title' => 'chapter 2',
          'type' => 'part',
          'children' => [
            {
              'id' => 3,
              'title' => 'third page',
              'type' => 'page',
              'path' => '1.3'
            }
          ]
        }
      ]
    }])
  end

  it "should get tagged exercises out of a book" do

    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 1, tags: ['ost-tag-lo-topic1-lo1','concept'])
    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 2, tags: ['ost-tag-lo-topic2-lo2','homework'])
    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 3, tags: ['ost-tag-lo-topic3-lo3','concept'])

    Content::Routines::ImportExercises.call(tag: 'ost-tag-lo-topic1-lo1')
    Content::Routines::ImportExercises.call(tag: 'ost-tag-lo-topic2-lo2')
    Content::Routines::ImportExercises.call(tag: 'ost-tag-lo-topic3-lo3')

    exercises = Content::VisitBook[book: root_book_part.book,
                                   visitor_names: :exercises]

    expect(exercises).to include({
      '1@1' => {
        'uid' => '1@1',
        'id' => 1,
        'url' => a_kind_of(String),
        'los' => ['ost-tag-lo-topic1-lo1'],
        'tags' => ['concept']
      },
      '2@1' => {
        'uid' => '2@1',
        'id' => 2,
        'url' => a_kind_of(String),
        'los' => ['ost-tag-lo-topic2-lo2'],
        'tags' => ['homework']
      },
      '3@1' => {
        'uid' => '3@1',
        'id' => 3,
        'url' => a_kind_of(String),
        'los' => ['ost-tag-lo-topic3-lo3'],
        'tags' => ['concept']
      }
    })

  end

end
