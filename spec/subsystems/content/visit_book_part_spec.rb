require 'rails_helper'

RSpec.describe Content::VisitBookPart, :type => :routine do

  around(:each) do |example|
    OpenStax::Exercises::V1.use_fake_client
    OpenStax::Exercises::V1.fake_client.reset!
    example.run
    OpenStax::Exercises::V1.fake_client.reset!
  end

  let!(:book_part) {
    FactoryGirl.create(:content_book_part, :standard_contents_1)
  }

  it "should get the TOC with the TOC option" do

    toc = Content::VisitBookPart[book_part: book_part, visitor_names: :toc]
    ftoc = toc.first
    expect(toc).to eq([{
      'id' => ftoc.id,
      'title' => 'unit 1',
      'type' => 'part',
      'children' => [
        {
          'id' => ftoc.children[0].id,
          'title' => 'chapter 1',
          'type' => 'part',
          'children' => [
            {
              'id' => ftoc.children[0].children[0].id,
              'title' => 'first page',
              'type' => 'page',
              'chapter_section' => '1.1'
            },
            {
              'id' => ftoc.children[0].children[1].id,
              'title' => 'second page',
              'type' => 'page',
              'chapter_section' => '1.2'
            }
          ],
          'chapter_section' => nil
        },
        {
          'id' => ftoc.children[1].id,
          'title' => 'chapter 2',
          'type' => 'part',
          'children' => [
            {
              'id' => ftoc.children[1].children[0].id,
              'title' => 'third page',
              'type' => 'page',
              'chapter_section' => '1.3'
            }
          ],
          'chapter_section' => nil
        }
      ],
      'chapter_section' => nil
    }])
  end

  it "should get tagged exercises out of a book_part" do

    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 1, tags: ['ost-tag-lo-topic1-lo1','concept'])
    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 2, tags: ['ost-tag-lo-topic2-lo2','homework'])
    OpenStax::Exercises::V1.fake_client.add_exercise(uid: 3, tags: ['ost-tag-lo-topic3-lo3','concept'])

    Content::Routines::ImportExercises.call(tag: 'ost-tag-lo-topic1-lo1')
    Content::Routines::ImportExercises.call(tag: 'ost-tag-lo-topic2-lo2')
    Content::Routines::ImportExercises.call(tag: 'ost-tag-lo-topic3-lo3')

    exercises = Content::VisitBookPart[book_part: book_part,
                                       visitor_names: :exercises]

    expect(exercises).to include({
      '1@1' => {
        'uid' => '1@1',
        'id' => exercises['1@1']['id'],
        'url' => a_kind_of(String),
        'los' => ['ost-tag-lo-topic1-lo1'],
        'tags' => ['concept']
      },
      '2@1' => {
        'uid' => '2@1',
        'id' => exercises['2@1']['id'],
        'url' => a_kind_of(String),
        'los' => ['ost-tag-lo-topic2-lo2'],
        'tags' => ['homework']
      },
      '3@1' => {
        'uid' => '3@1',
        'id' => exercises['3@1']['id'],
        'url' => a_kind_of(String),
        'los' => ['ost-tag-lo-topic3-lo3'],
        'tags' => ['concept']
      }
    })

  end

end
