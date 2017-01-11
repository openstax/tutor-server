require 'rails_helper'

RSpec.describe Catalog::UpdateOffering, type: :routine do

  let(:old_ecosystem) { FactoryGirl.create :content_ecosystem }
  let(:new_ecosystem) { FactoryGirl.create :content_ecosystem }

  let(:offering)      { FactoryGirl.create :catalog_offering, ecosystem: old_ecosystem }

  let(:courses)       do
    3.times.map do
      FactoryGirl.create(:course_profile_course, offering: offering).tap do |course|
        course.ecosystems << old_ecosystem
      end
    end
  end

  let(:new_attributes) do
    {
      salesforce_book_name: 'new_book',
      appearance_code: 'new',
      is_tutor: true,
      is_concept_coach: false,
      is_available: true,
      title: 'New Book',
      description: 'Newest of the new',
      webview_url: 'http://www.example.com',
      pdf_url: 'http://www.example.pdf'
    }
  end

  it "updates the offering's attributes" do
    described_class.call(offering.id, new_attributes)
    str_attributes = new_attributes.stringify_keys
    expect(offering.reload.attributes.slice(*str_attributes.keys)).to eq str_attributes
  end

  context 'update_courses is true' do
    it "updates associated courses' ecosystems if the ecosystem is changed" do
      courses.each{ |course| expect(course.ecosystems.first).to eq old_ecosystem }

      described_class.call(offering.id, {ecosystem: new_ecosystem}, true)

      courses.each{ |course| expect(course.reload.ecosystems.first).to eq new_ecosystem }
    end
  end

  context 'update_courses is false' do
    it "does not updates associated courses' ecosystems" do
      courses.each{ |course| expect(course.ecosystems.first).to eq old_ecosystem }

      described_class.call(offering.id, {ecosystem: new_ecosystem}, false)

      courses.each{ |course| expect(course.reload.ecosystems.first).to eq old_ecosystem }
    end
  end

end
