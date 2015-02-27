require 'rails_helper'

RSpec.describe Content::ImportPage, :type => :routine do
  # The module specified here should ideally contain:
  # - Absolute URL's
  # - Relative URL's
  # - Topic (LO)-tagged sections and problems
  fixture_file = 'spec/fixtures/m50577/index.cnxml.html'

  let!(:book_part) { FactoryGirl.create :content_book_part }

  before(:each) do
    hash = {
      title: 'Dummy',
      id: 'dummy',
      version: '1.0',
      content: open(fixture_file) { |f| f.read }
    }

    allow_any_instance_of(Content::ImportCnxResource).to(
      receive(:open).and_return(hash.to_json))
  end

  it 'creates a new Page' do
    result = nil
    expect {
      result = Content::ImportPage.call(id: 'dummy', book_part: book_part)
    }.to change{ Content::Page.count }.by(1)
    expect(result.errors).to be_empty

    expect(result.outputs[:page]).to be_persisted
    expect(result.outputs[:url]).not_to be_blank
    expect(result.outputs[:content]).not_to be_blank
  end

  it 'converts relative links into absolute links' do
    page = Content::ImportPage.call(id: 'dummy', book_part: book_part).outputs[:page]
    doc = Nokogiri::HTML(page.content)

    doc.css("*[src]").each do |tag|
      uri = URI.parse(URI.escape(tag.attributes["src"].value))
      expect(uri.absolute?).to eq true
    end
  end

  it 'finds LO tags in the content' do
    result = nil
    expect {
      result = Content::ImportPage.call(id: 'dummy', book_part: book_part)
    }.to change{ Content::Topic.count }.by(3)

    topics = Content::Topic.all.to_a
    expect(topics[-3].name).to eq 'ost-topic-apphys-ch5-s1-lo1'
    expect(topics[-2].name).to eq 'ost-topic-apphys-ch5-s1-lo2'
    expect(topics[-1].name).to eq 'ost-topic-apphys-ch5-s1-lo3'

    tagged_topics = result.outputs[:topics]
    expect(tagged_topics).not_to be_empty
    expect(tagged_topics).to eq Content::Page.last.page_topics.collect{|pt| pt.topic}
    expect(tagged_topics.collect{|t| t.name}).to eq [
      'ost-topic-apphys-ch5-s1-lo1',
      'ost-topic-apphys-ch5-s1-lo2',
      'ost-topic-apphys-ch5-s1-lo3'
    ]
  end

  it 'gets exercises with LO tags from the content' do
    OpenStax::Exercises::V1.fake_client.reset!

    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo1']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo2']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo3']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo2']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo2', 'ost-topic-apphys-ch5-s1-lo3']
    )
    OpenStax::Exercises::V1.fake_client.add_exercise(
      tags: ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo3']
    )

    result = nil
    expect {
      result = Content::ImportPage.call('dummy', book)
    }.to change{ Content::Exercise.count }.by(6)

    exercises = Content::Exercise.all.to_a
    expect(exercises[-6].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo1']
    expect(exercises[-5].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo2']
    expect(exercises[-4].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo3']
    expect(exercises[-3].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo2']
    expect(exercises[-2].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo2', 'ost-topic-apphys-ch5-s1-lo3']
    expect(exercises[-1].exercise_topics.collect{|et| et.topic.name})
      .to eq ['ost-topic-apphys-ch5-s1-lo1', 'ost-topic-apphys-ch5-s1-lo3']

    OpenStax::Exercises::V1.fake_client.reset!
  end
end
