require 'rails_helper'

RSpec.describe Api::V1::CourseRepresenter, type: :representer do
  let!(:ecosystem)        { Content::Models::Ecosystem.create!(title: 'Test eco') }
  let!(:catalog_offering) { Catalog::CreateOffering[salesforce_book_name: 'book',
                                                    appearance_code: 'appearance',
                                                    webview_url: 'web_url',
                                                    pdf_url: 'pdf_url',
                                                    description: 'desc',
                                                    ecosystem: ecosystem] }
  let!(:course)           { CreateCourse[name: 'Test course',
                                         appearance_code: 'appearance override',
                                         catalog_offering: catalog_offering,
                                         is_concept_coach: true] }

  subject(:represented) { described_class.new(course).to_hash }

  it 'shows the course id' do
    expect(represented['id']).to eq course.id.to_s
  end

  it 'shows the course name' do
    expect(represented['name']).to eq 'Test course'
  end

  it 'shows the offering salesforce_book_name' do
    expect(represented['salesforce_book_name']).to eq 'book'
  end

  it 'shows the profile appearance_code' do
    expect(represented['appearance_code']).to eq 'appearance override'
  end

  it 'shows the offering appearance_code if the profile appearance_code is blank' do
    course.profile.update_attribute(:appearance_code, nil)
    expect(represented['appearance_code']).to eq 'appearance'
  end

  it 'shows the book_pdf_url if available' do
    expect(represented['book_pdf_url']).to eq 'pdf_url'
  end

  it 'shows the webview_url if avail' do
    expect(represented['webview_url']).to eq 'web_url'
  end

  it 'shows whether or not the course is a concept coach course' do
    expect(represented['is_concept_coach']).to eq true
  end

  it 'shows students' do
    output = described_class.new(Hashie::Mash.new({students: [{id: 32}, {id: 65}]})).to_hash
    expect(output["students"]).to match [a_hash_including("id" => "32"), a_hash_including("id" => "65")]
  end
end
