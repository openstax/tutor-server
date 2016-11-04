require 'rails_helper'

RSpec.describe ImportSalesforceCourse, type: :routine do

  before(:all) { @new_sf_id ||= 0 }

  it 'can run successfully' do
    offering = FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                                  default_course_name: "Yo", is_concept_coach: true)
    candidate = new_osa(book_name: "jimmy", product: "Concept Coach",
                        school: "Rice", account_type: "College/University (4)")

    outputs = described_class.call(candidate: candidate).outputs

    expect(candidate.error).to be_nil
    expect(candidate.num_students).to eq 0
    expect(candidate.num_teachers).to eq 0
    expect(candidate.num_sections).to eq 0
    expect(candidate.teacher_join_url).to match /http.*\/teach\/[a-f0-9]+\/DO_NOT/

    course = outputs.course

    expect(course.name).to eq "Yo"
    expect(course.school.name).to eq "Rice"
    expect(course.is_concept_coach).to be_truthy
    expect(course.is_college).to be_truthy

    attached_record = Salesforce::Models::AttachedRecord.first
    expect(attached_record.attached_to).to eq course
    expect(attached_record.salesforce_id).to eq candidate.id.to_s

    ecosystem = GetCourseEcosystem[course: course]
    expect(ecosystem.id).to eq offering.content_ecosystem_id
  end

  it 'errors when the book name does not match an offering in tutor' do
    error = "Book Name does not match an offering in Tutor."
    expect_import_error(new_osa(book_name: "jimmy"), error)
    expect_import_error(new_cs(book_name: "jimmy"), error)
  end

  it 'errors when the OSA product is no good' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy", is_concept_coach: false)

    expect_import_error(
      new_osa(book_name: "jimmy", product: "Tutor Extreme"),
      "Status is approved but 'Product' is missing or has an unexpected value."
    )
  end

  context "when the matching offering is for Tutor and not CC" do
    let(:error) { "Book Name matches an offering in Tutor but not for Concept Coach courses." }
    before { FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                                is_tutor: true, is_concept_coach: false) }

    it "errors when OSA is for CC" do
      expect_import_error(new_osa(book_name: "jimmy", product: "Concept Coach"), error)
    end

    it "errors for CS" do
      expect_import_error(new_cs(book_name: "jimmy"), error)
    end

    it "does not error when OSA is for Tutor" do
      expect_no_import_error(new_osa(book_name: "jimmy", product: "Tutor", school: "blah U"))
    end
  end

  context "when the matching offering is for CC and not Tutor" do
    before { FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                                is_tutor: false, is_concept_coach: true) }

    it "errors when the OSA is for Tutor" do
      expect_import_error(
        new_osa(book_name: "jimmy", product: "Tutor"),
        "Book Name matches an offering in Tutor but not for full Tutor courses."
      )
    end

    it "does not error for CS" do
      expect_no_import_error(new_cs(book_name: "jimmy", school: "blah U"))
    end
  end

  it 'errors when there is no course name' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                       default_course_name: nil, is_concept_coach: true)

    error = "A course name is needed and no default is available in Tutor."

    expect_import_error(
      new_osa(book_name: "jimmy", course_name: nil, product: "Concept Coach"), error
    )
    expect_import_error(new_cs(book_name: "jimmy", course_name: nil), error)
  end

  it 'errors when there is no school' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                       default_course_name: nil, is_concept_coach: true)
    error = "A school is required."

    expect_import_error(
      new_osa(book_name: "jimmy", course_name: "Yo", product: "Concept Coach"), error
    )
    expect_import_error(new_cs(book_name: "jimmy", course_name: "Yo"), error)
  end

  it 'reuses existing schools' do
    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                       default_course_name: "Yo", is_concept_coach: true)

    expect {
      described_class[candidate: new_osa(book_name: "jimmy",
                                         product: "Concept Coach",
                                         school: "Rice U")]
    }.to change{SchoolDistrict::Models::School.count}.by(1)

    expect {
      described_class[candidate: new_osa(book_name: "jimmy",
                                         product: "Concept Coach",
                                         school: "Rice U")]
    }.not_to change{SchoolDistrict::Models::School.count}
  end

  def new_osa(args={})
    # All SF objects we get from SF will have an ID and a term_year
    args[:id] = (@new_sf_id += 1).to_s
    args[:term_year] ||= '2015 - 16 Spring'
    Salesforce::Remote::OsAncillary.new(args)
  end

  def new_cs(args={})
    # All SF objects we get from SF will have an ID and a term_year
    args[:id] = (@new_sf_id += 1).to_s
    args[:term_year] ||= '2015 - 16 Spring'
    Salesforce::Remote::ClassSize.new(args)
  end

  def expect_import_error(candidate, error_message)
    expect{
      described_class[candidate: candidate]
    }.not_to change{ CourseProfile::Models::Course.count }

    expect(candidate.error).to eq error_message
  end

  def expect_no_import_error(candidate)
    described_class[candidate: candidate]
    expect(candidate.error).to be_blank
  end

end
