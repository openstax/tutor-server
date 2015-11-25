require 'rails_helper'

RSpec.describe ImportSalesforceCourses, type: :routine do

  it 'restricts to Denver University when asked to not run on real data' do
    allow(Salesforce::Remote::ClassSize).to receive(:where).and_return([])

    expect(Salesforce::Remote::ClassSize).to receive(:where).with(
      concept_coach_approved: true,
      course_id: nil,
      school: 'Denver University'
    )

    ImportSalesforceCourses[include_real_salesforce_data: false]
  end

  it 'does not restrict to Denver University when told to include real data' do
    allow(Salesforce::Remote::ClassSize).to receive(:where).and_return([])

    expect(Salesforce::Remote::ClassSize).to receive(:where).with(
      concept_coach_approved: true,
      course_id: nil
    )

    ImportSalesforceCourses[include_real_salesforce_data: true]
  end

  it 'errors when the book name does not match an offering in tutor' do
    disable_sfdc_client

    class_size = Salesforce::Remote::ClassSize.new(book_name: "jimmy")

    allow_any_instance_of(described_class)
      .to receive(:candidate_sf_records)
      .and_return([class_size])

    result = ImportSalesforceCourses.call

    expect(class_size.error).to eq "Book Name does not match an offering in Tutor."
    expect(result.outputs.num_failures).to eq 1
    expect(result.outputs.num_successes).to eq 0
  end

  it 'errors when the book name matches a non CC offering' do
    disable_sfdc_client

    class_size = Salesforce::Remote::ClassSize.new(book_name: "jimmy")
    FactoryGirl.create(:catalog_offering, identifier: "jimmy")

    allow_any_instance_of(described_class)
      .to receive(:candidate_sf_records)
      .and_return([class_size])

    ImportSalesforceCourses[]

    expect(class_size.error).to eq "Book Name matches a Tutor offering but it isn't for CC."
  end

  it 'errors when there is no course name' do
    disable_sfdc_client

    class_size = Salesforce::Remote::ClassSize.new(book_name: "jimmy", course_name: nil)
    FactoryGirl.create(:catalog_offering,
      identifier: "jimmy", default_course_name: nil, is_concept_coach: true)

    allow_any_instance_of(described_class)
      .to receive(:candidate_sf_records)
      .and_return([class_size])

    ImportSalesforceCourses[]

    expect(class_size.error).to eq "A course name is needed and no default is available in Tutor."
  end

  it 'creates a course and returns info' do
    disable_sfdc_client

    class_size = Salesforce::Remote::ClassSize.new(
      book_name: "jimmy", course_name: "Jimmyness 101", school: "Jimmy U", id: 'booyah')
    offering = FactoryGirl.create(:catalog_offering,
      identifier: "jimmy", default_course_name: nil, is_concept_coach: true)
    FactoryGirl.create(:school, name: "Jimmy U")

    allow_any_instance_of(described_class)
      .to receive(:candidate_sf_records)
      .and_return([class_size])

    expect(class_size).to receive(:save)

    result = nil
    expect {
      result = ImportSalesforceCourses.call
    }.to change{Entity::Course.count}.by(1)
     .and change{Salesforce::Models::AttachedRecord.count}.by(1)
    expect(result.errors).to be_empty

    created_course = Entity::Course.first

    expect(class_size.course_id).to eq created_course.id
    expect(class_size.created_at).to be_a String
    expect(class_size.num_students).to eq 0
    expect(class_size.num_teachers).to eq 0
    expect(class_size.teacher_join_url).to include "courses/join/"

    course_ecosystem = CourseContent::Models::CourseEcosystem.first
    expect(course_ecosystem.course).to eq created_course
    expect(course_ecosystem.ecosystem).to eq offering.ecosystem

    expect(result.outputs.num_failures).to eq 0
    expect(result.outputs.num_successes).to eq 1
  end

  def disable_sfdc_client
    allow(ActiveForce)
      .to receive(:sfdc_client)
      .and_return(double('null object').as_null_object)
  end

end
