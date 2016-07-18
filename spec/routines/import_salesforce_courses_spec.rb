require 'rails_helper'

RSpec.describe ImportSalesforceCourses, type: :routine do

  let(:osa_class) { Salesforce::Remote::OsAncillary }
  let(:cs_class)  { Salesforce::Remote::ClassSize }

  it 'restricts to Denver University when asked to not run on real data' do
    allow(osa_class).to receive(:where).and_return([])
    allow(cs_class).to receive(:where).and_return([])

    expect(osa_class).to receive(:where).with(
      status: "Approved",
      course_id: nil,
      school: 'Denver University'
    )

    expect(cs_class).to receive(:where).with(
      concept_coach_approved: true,
      course_id: nil,
      school: 'Denver University'
    )

    ImportSalesforceCourses.call(include_real_salesforce_data: false)
  end

  it 'restricts to Denver University when told to include real data but global secrets flag false' do
    allow(osa_class).to receive(:where).and_return([])
    allow(cs_class).to receive(:where).and_return([])
    allow(Rails.application.secrets.salesforce).to(
      receive(:[]).with('allow_use_of_real_data').and_return false
    )

    expect(osa_class).to receive(:where).with(
      status: "Approved",
      course_id: nil,
      school: 'Denver University'
    )

    expect(cs_class).to receive(:where).with(
      concept_coach_approved: true,
      course_id: nil,
      school: 'Denver University'
    )

    ImportSalesforceCourses.call(include_real_salesforce_data: true)
  end

  it 'does not restrict to Denver University when told to include real data' do
    allow(osa_class).to receive(:where).and_return([])
    allow(cs_class).to receive(:where).and_return([])
    allow(Rails.application.secrets.salesforce).to(
      receive(:[]).with('allow_use_of_real_data').and_return true
    )

    expect(osa_class).to receive(:where).with(
      status: "Approved",
      course_id: nil
    )

    expect(cs_class).to receive(:where).with(
      concept_coach_approved: true,
      course_id: nil
    )

    ImportSalesforceCourses.call(include_real_salesforce_data: true)
  end

  it 'creates a course and returns info' do
    disable_sfdc_client

    sf_record = osa_class.new(
      book_name: "jimmy", course_name: "Jimmyness 101",
      school: "Jimmy U", id: 'booyah', product: "Concept Coach"
    )
    offering = FactoryGirl.create(:catalog_offering,
      salesforce_book_name: "jimmy", default_course_name: nil, is_concept_coach: true
    )

    stub_candidates(osa: sf_record)

    expect(sf_record).to receive(:save)

    result = nil
    expect {
      result = ImportSalesforceCourses.call
    }.to change{Entity::Course.count}.by(1)
     .and change{Salesforce::Models::AttachedRecord.count}.by(1)

    created_course = Entity::Course.first

    expect(sf_record.course_id).to eq created_course.id
    expect(sf_record.created_at).to be_a String
    expect(sf_record.num_students).to eq 0
    expect(sf_record.num_teachers).to eq 0
    expect(sf_record.teacher_join_url).to match /.*teach\/[a-f0-9]{32}\/DO_NOT.*/

    course_ecosystem = CourseContent::Models::CourseEcosystem.first
    expect(course_ecosystem.course).to eq created_course
    expect(course_ecosystem.ecosystem).to eq offering.ecosystem

    expect(result.num_failures).to eq 0
    expect(result.num_successes).to eq 1
  end

  it 'does not rollback successful imports if import blows up' do
    # rolling back successful imports is bad because whatever was written to SF
    # after success is not rolled back, and our data gets out of sync.

    disable_sfdc_client

    offering = FactoryGirl.create(:catalog_offering,
      salesforce_book_name: "jimmy", default_course_name: nil, is_concept_coach: true
    )

    sf_record = osa_class.new(
      book_name: "jimmy", course_name: "Jimmyness 101",
      school: "Jimmy U", id: 'booyah', product: "Concept Coach"
    )

    # 2nd candidate here is going to force a blow up with NoMethodError:
    # undefined method `something here' for nil:NilClass
    stub_candidates(osa: [sf_record, nil])

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

    sf_record = osa_class.new(
      book_name: "jimmy", course_name: "Jimmyness 101",
      school: "Jimmy U", id: 'booyah', product: "Concept Coach"
    )

    stub_candidates(osa: sf_record)

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

  def stub_candidates(osa: [], cs: [])
    allow_any_instance_of(described_class)
      .to receive(:candidate_os_ancillary_records)
      .and_return([osa].flatten)

    allow_any_instance_of(described_class)
      .to receive(:candidate_class_size_records)
      .and_return([cs].flatten)
  end

end
