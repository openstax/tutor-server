require 'rails_helper'

RSpec.describe ImportPage, :type => :routine do
  # The module specified here should ideally contain:
  # - Absolute URL's
  # - Relative URL's
  # - Topic (LO)-tagged sections and problems
  fixture_file = 'spec/fixtures/m50577/index.cnxml.html'

  let!(:book) { FactoryGirl.create :book }

  before(:each) do
    hash = {
      title: 'Dummy',
      id: 'dummy',
      version: '1.0',
      content: open(fixture_file) { |f| f.read }
    }

    allow_any_instance_of(GetCnxJson).to(
      receive(:open).and_return(hash.to_json))
  end

  it 'creates a new Resource' do
    result = nil
    expect {
      result = ImportPage.call('dummy', book)
    }.to change{ Resource.count }.by(1)
    expect(result.errors).to be_empty
    expect(result.outputs[:resource]).to be_persisted
  end

  it 'creates a new Page' do
    result = nil
    expect {
      result = ImportPage.call('dummy', book)
    }.to change{ Page.count }.by(1)
    expect(result.errors).to be_empty
    expect(result.outputs[:page]).to be_persisted
  end

  it 'converts relative links into absolute links' do
    page = ImportPage.call('dummy', book).outputs[:page]
    doc = Nokogiri::HTML(page.content)

    doc.css("*[src]").each do |tag|
      uri = URI.parse(URI.escape(tag.attributes["src"].value))
      expect(uri.absolute?).to eq true
    end
  end

  it 'finds LO tags in the content' do
    pts = nil
    expect {
      pts = ImportPage.call('dummy', book).outputs[:page_topics]
    }.to change{ Topic.count }.by(3)

    topics = Topic.all.to_a
    expect(topics[-3].name).to eq 'ost-apphys-ch5-s1-lo1'
    expect(topics[-2].name).to eq 'ost-apphys-ch5-s1-lo2'
    expect(topics[-1].name).to eq 'ost-apphys-ch5-s1-lo3'
    expect(pts).not_to be_empty
    expect(pts).to eq Page.last.page_topics
    expect(pts.collect{ |pt| pt.topic }).to(
      eq [topics[-3], topics[-2], topics[-1]])
  end
end
