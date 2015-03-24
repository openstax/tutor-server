require 'rails_helper'

RSpec.describe Content::Api::VisitBook, :type => :routine do

  around(:each) do |example|
    OpenStax::Exercises::V1.use_fake_client
    OpenStax::Exercises::V1.fake_client.reset!
    example.run
    OpenStax::Exercises::V1.fake_client.reset!
  end

  let!(:root_book_part) { FactoryGirl.create(:content_book_part, :standard_contents_1) }

  it "should get the TOC with the TOC option" do
    
    result = Content::Api::VisitBook.call(book: root_book_part.book, visitor_names: :toc)

    expect(result.outputs.toc).to eq([{
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
              'type' => 'page'
            },
            {
              'id' => 2,
              'title' => 'second page',
              'type' => 'page'
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
              'type' => 'page'
            }
          ]
        }
      ]      
    }])
  end

  it "should get tagged exercises out of a book" do

    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 1, tags: ['ost-tag-lo-topic1-lo1'])
    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 2, tags: ['ost-tag-lo-topic2-lo2'])
    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 3, tags: ['ost-tag-lo-topic3-lo3'])
      
    Content::ImportExercises.call(tag: 'ost-tag-lo-topic1-lo1')
    Content::ImportExercises.call(tag: 'ost-tag-lo-topic2-lo2')
    Content::ImportExercises.call(tag: 'ost-tag-lo-topic3-lo3')

    result = Content::Api::VisitBook.call(book: root_book_part.book, 
                                          visitor_names: :exercises)

    expect(result.outputs.exercises).to include({
      '1@1' => {
        'id' => 1,
        'url' => a_kind_of(String),
        'topics' => ['ost-tag-lo-topic1-lo1']
      },
      '2@1' => {
        'id' => 2,
        'url' => a_kind_of(String),
        'topics' => ['ost-tag-lo-topic2-lo2']
      },
      '3@1' => {
        'id' => 3,
        'url' => a_kind_of(String),
        'topics' => ['ost-tag-lo-topic3-lo3']
      }
    })

  end

end

      