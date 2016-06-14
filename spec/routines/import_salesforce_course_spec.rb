require 'rails_helper'

RSpec.describe ImportSalesforceCourse, type: :routine do

  let(:sf_record_class) { Salesforce::Remote::OsAncillary }

  it 'errors when the book name does not match an offering in tutor' do
    expect_import_error(
      sf_record_class.new(book_name: "jimmy"),
      "Book Name does not match an offering in Tutor."
    )
  end

  it 'errors when the product is no good' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy", is_concept_coach: false)

    expect_import_error(
      sf_record_class.new(book_name: "jimmy", product: "Tutor Extreme"),
      "Status is approved but 'Product' is missing or has an unexpected value."
    )
  end

  it 'errors when the SF record is for CC but the matching offering is not' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy", is_concept_coach: false)

    expect_import_error(
      sf_record_class.new(book_name: "jimmy", product: "Concept Coach"),
      "Book Name matches an offering in Tutor but not for Concept Coach courses."
    )
  end

  it 'errors when the SF record is for Tutor but the matching offering is not' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy", is_tutor: false)

    expect_import_error(
      sf_record_class.new(book_name: "jimmy", product: "Tutor"),
      "Book Name matches an offering in Tutor but not for full Tutor courses."
    )
  end

  # TODO test other things!

  it 'errors when there is no course name' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                       default_course_name: nil, is_concept_coach: true)

    expect_import_error(
      sf_record_class.new(book_name: "jimmy", course_name: nil, product: "Concept Coach"),
      "A course name is needed and no default is available in Tutor."
    )
  end

  it 'errors when there is no school' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                       default_course_name: nil, is_concept_coach: true)

    expect_import_error(
      sf_record_class.new(book_name: "jimmy", course_name: "Yo", product: "Concept Coach"),
      "A school is required."
    )
  end

  def expect_import_error(candidate, error_message)
    expect{
      described_class.call(candidate: candidate)
    }.to change{Entity::Course.count}.by(0)

    expect(candidate.error).to eq error_message
  end

end
