require 'rails_helper'

RSpec.describe Api::V1::CourseRepresenter, type: :representer do
  let!(:ecosystem)        { Content::Models::Ecosystem.create!(title: 'Test eco') }
  let!(:catalog_offering) { Catalog::CreateOffering[identifier: 'identifier',
                                                    webview_url: 'web_url',
                                                    pdf_url: 'pdf_url',
                                                    description: 'desc',
                                                    ecosystem: ecosystem] }
  let!(:course)           { CreateCourse[name: 'Test course',
                                         catalog_offering: catalog_offering,
                                         is_concept_coach: true] }

  subject(:represented) { described_class.new(course).to_hash }

  it 'shows the course id' do
    expect(represented['id']).to eq course.id.to_s
  end

  it 'shows the course name' do
    expect(represented['name']).to eq 'Test course'
  end

  it 'shows the catalog_offering_identifier' do
    expect(represented['catalog_offering_identifier']).to eq 'identifier'
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
end
