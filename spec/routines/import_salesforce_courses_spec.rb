require 'rails_helper'

RSpec.describe ImportSalesforceCourses, type: :routine do

  let(:sf_record_class) { Salesforce::Remote::OsAncillary }

  it 'restricts to Denver University when asked to not run on real data' do
    allow(sf_record_class).to receive(:where).and_return([])

    expect(sf_record_class).to receive(:where).with(
      status: "Approved",
      course_id: nil,
      school: 'Denver University'
    )

    ImportSalesforceCourses[include_real_salesforce_data: false]
  end

  it 'restricts to Denver University when told to include real data but global secrets flag false' do
    allow(sf_record_class).to receive(:where).and_return([])
    allow(Rails.application.secrets.salesforce).to receive(:[]).with('allow_use_of_real_data').and_return false

    expect(sf_record_class).to receive(:where).with(
      status: "Approved",
      course_id: nil,
      school: 'Denver University'
    )

    ImportSalesforceCourses[include_real_salesforce_data: true]
  end

  it 'does not restrict to Denver University when told to include real data' do
    allow(sf_record_class).to receive(:where).and_return([])
    allow(Rails.application.secrets.salesforce).to receive(:[]).with('allow_use_of_real_data').and_return true

    expect(sf_record_class).to receive(:where).with(
      status: "Approved",
      course_id: nil
    )

    ImportSalesforceCourses[include_real_salesforce_data: true]
  end

  it 'errors when the book name does not match an offering in tutor' do
    disable_sfdc_client

    sf_record = sf_record_class.new(book_name: "jimmy")
    stub_candidates(sf_record)

    result = ImportSalesforceCourses.call

    expect(sf_record.error).to eq "Book Name does not match an offering in Tutor."
    expect(result.outputs.num_failures).to eq 1
    expect(result.outputs.num_successes).to eq 0
  end

  it 'errors when the product is no good' do
    disable_sfdc_client

    sf_record = sf_record_class.new(book_name: "jimmy", product: "Tutor Extreme")
    stub_candidates(sf_record)

    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy", is_concept_coach: false)

    ImportSalesforceCourses[]

    expect(sf_record.error).to eq "Status is approved but 'Product' is missing or has an unexpected value."
  end

  it 'errors when the SF record is for CC but the matching offering is not' do
    disable_sfdc_client

    sf_record = sf_record_class.new(book_name: "jimmy", product: "Concept Coach")
    stub_candidates(sf_record)

    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy", is_concept_coach: false)

    ImportSalesforceCourses[]

    expect(sf_record.error).to eq "Book Name matches an offering in Tutor but not for Concept Coach courses."
  end

  it 'errors when the SF record is for Tutor but the matching offering is not' do
    disable_sfdc_client

    sf_record = sf_record_class.new(book_name: "jimmy", product: "Tutor")
    stub_candidates(sf_record)

    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy", is_tutor: false)

    ImportSalesforceCourses[]

    expect(sf_record.error).to eq "Book Name matches an offering in Tutor but not for full Tutor courses."
  end

  # TODO test other things!

  it 'errors when there is no course name' do
    disable_sfdc_client

    sf_record = sf_record_class.new(book_name: "jimmy", course_name: nil, product: "Concept Coach")
    stub_candidates(sf_record)

    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                       default_course_name: nil, is_concept_coach: true)

    ImportSalesforceCourses[]

    expect(sf_record.error).to eq "A course name is needed and no default is available in Tutor."
  end

  it 'errors when there is no school' do
    disable_sfdc_client

    sf_record = sf_record_class.new(book_name: "jimmy", course_name: "Yo", product: "Concept Coach")
    stub_candidates(sf_record)

    FactoryGirl.create(:catalog_offering, salesforce_book_name: "jimmy",
                       default_course_name: nil, is_concept_coach: true)

    ImportSalesforceCourses[]

    expect(sf_record.error).to eq "A school is required."
  end

  it 'creates a course and returns info' do
    disable_sfdc_client

    sf_record = sf_record_class.new(
      book_name: "jimmy", course_name: "Jimmyness 101",
      school: "Jimmy U", id: 'booyah', product: "Concept Coach"
    )
    offering = FactoryGirl.create(:catalog_offering,
      salesforce_book_name: "jimmy", default_course_name: nil, is_concept_coach: true
    )

    stub_candidates(sf_record)

    expect(sf_record).to receive(:save)

    result = nil
    expect {
      result = ImportSalesforceCourses.call
    }.to change{Entity::Course.count}.by(1)
     .and change{Salesforce::Models::AttachedRecord.count}.by(1)
    expect(result.errors).to be_empty

    created_course = Entity::Course.first

    expect(sf_record.course_id).to eq created_course.id
    expect(sf_record.created_at).to be_a String
    expect(sf_record.num_students).to eq 0
    expect(sf_record.num_teachers).to eq 0
    expect(sf_record.teacher_join_url).to match /.*teach\/[a-f0-9]{32}\/DO_NOT.*/

    course_ecosystem = CourseContent::Models::CourseEcosystem.first
    expect(course_ecosystem.course).to eq created_course
    expect(course_ecosystem.ecosystem).to eq offering.ecosystem

    expect(result.outputs.num_failures).to eq 0
    expect(result.outputs.num_successes).to eq 1
  end

  it 'does not rollback successful imports if import blows up' do
    # rolling back successful imports is bad because whatever was written to SF
    # after success is not rolled back, and our data gets out of sync.

    disable_sfdc_client

    offering = FactoryGirl.create(:catalog_offering,
      salesforce_book_name: "jimmy", default_course_name: nil, is_concept_coach: true
    )

    sf_record = sf_record_class.new(
      book_name: "jimmy", course_name: "Jimmyness 101",
      school: "Jimmy U", id: 'booyah', product: "Concept Coach"
    )

    # 2nd candidate here is going to force a blow up with NoMethodError:
    # undefined method `something here' for nil:NilClass
    stub_candidates([sf_record, nil])

    expect {
      ImportSalesforceCourses.call rescue NoMethodError
    }.to change{Entity::Course.count}.by(1)
  end

  it 'rolls back creation if there is a problem' do
    # This is checking that each candidate is handled within a transaction
    disable_sfdc_client

    offering = FactoryGirl.create(:catalog_offering,
      salesforce_book_name: "jimmy", default_course_name: nil, is_concept_coach: true
    )

    sf_record = sf_record_class.new(
      book_name: "jimmy", course_name: "Jimmyness 101",
      school: "Jimmy U", id: 'booyah', product: "Concept Coach"
    )

    stub_candidates(sf_record)

    allow_any_instance_of(offering.class).to receive(:ecosystem).and_raise(NoMethodError)

    expect {
      ImportSalesforceCourses.call rescue NoMethodError
    }.to change{Entity::Course.count}.by(0)
  end

  def disable_sfdc_client
    allow(ActiveForce)
      .to receive(:sfdc_client)
      .and_return(double('null object').as_null_object)
  end

  def stub_candidates(candidates)
    allow_any_instance_of(described_class)
      .to receive(:candidate_sf_records)
      .and_return([candidates].flatten)
  end

end
