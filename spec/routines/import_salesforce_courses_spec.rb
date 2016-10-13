require 'rails_helper'

RSpec.describe ImportSalesforceCourses, type: :routine do

  let(:osa_class) { Salesforce::Remote::OsAncillary }
  let(:cs_class)  { Salesforce::Remote::ClassSize }

  let(:target_term_year) { '2015 - 16 Spring' }
  before(:each) do
    allow(Settings::Salesforce).to receive(:term_years_to_import) { target_term_year }
  end

  it 'restricts to Denver University when asked to not run on real data' do
    allow(osa_class).to receive(:where).and_return([])
    allow(cs_class).to receive(:where).and_return([])

    expect(osa_class).to receive(:where).with(
      status: "Approved",
      course_id: nil,
      school: 'Denver University',
      term_year: [target_term_year]
    )

    expect(cs_class).to receive(:where).with(
      concept_coach_approved: true,
      course_id: nil,
      school: 'Denver University',
      term_year: [target_term_year]
    )

    ImportSalesforceCourses.call(include_real_salesforce_data: false)
  end

  it 'restricts to Denver University when told to include real data but secrets flag false' do
    allow(osa_class).to receive(:where).and_return([])
    allow(cs_class).to receive(:where).and_return([])
    allow(Rails.application.secrets.salesforce).to(
      receive(:[]).with('allow_use_of_real_data').and_return false
    )

    expect(osa_class).to receive(:where).with(
      status: "Approved",
      course_id: nil,
      school: 'Denver University',
      term_year: [target_term_year]
    )

    expect(cs_class).to receive(:where).with(
      concept_coach_approved: true,
      course_id: nil,
      school: 'Denver University',
      term_year: [target_term_year]
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
      course_id: nil,
      term_year: [target_term_year]
    )

    expect(cs_class).to receive(:where).with(
      concept_coach_approved: true,
      course_id: nil,
      term_year: [target_term_year]
    )

    ImportSalesforceCourses.call(include_real_salesforce_data: true)
  end

  it 'creates a course and returns info' do
    disable_sfdc_client

    sf_record = osa_class.new(
      book_name: "jimmy",
      course_name: "Jimmyness 101",
      school: "Jimmy U",
      id: 'booyah',
      product: "Concept Coach",
      term_year: target_term_year
    )
    offering = FactoryGirl.create(:catalog_offering,
      salesforce_book_name: "jimmy",
      default_course_name: nil,
      is_concept_coach: true
    )

    stub_candidates(osa: sf_record)

    expect(sf_record).to receive(:save)

    before_course_ids = Entity::Course.all.map(&:id)

    result = nil
    expect {
      result = ImportSalesforceCourses.call
    }.to change{Entity::Course.count}.by(1)
     .and change{Salesforce::Models::AttachedRecord.count}.by(1)

    after_course_ids = Entity::Course.all.map(&:id)
    new_course_id = (after_course_ids - before_course_ids).first

    created_course = Entity::Course.find(new_course_id)

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

    offering = FactoryGirl.create(
      :catalog_offering,
      salesforce_book_name: "jimmy", default_course_name: nil, is_concept_coach: true
    )

    sf_record = osa_class.new(
      book_name: "jimmy",
      course_name: "Jimmyness 101",
      school: "Jimmy U",
      id: 'booyah',
      product: "Concept Coach",
      term_year: target_term_year
    )

    # 2nd candidate here is going to force a blow up with NoMethodError:
    # undefined method `something here' for nil:NilClass
    stub_candidates(osa: [sf_record, nil])

    expect do
      begin
        ImportSalesforceCourses.call
      rescue NoMethodError
      end
    end.to change{Entity::Course.count}.by(1)
  end

  it 'rolls back creation if there is a problem' do
    # This is checking that each candidate is handled within a transaction
    disable_sfdc_client

    offering = FactoryGirl.create(
      :catalog_offering,
      salesforce_book_name: "jimmy",
      default_course_name: nil,
      is_concept_coach: true
    )

    sf_record = osa_class.new(
      book_name: "jimmy",
      course_name: "Jimmyness 101",
      school: "Jimmy U",
      id: 'booyah',
      product: "Concept Coach",
      term_year: target_term_year
    )

    stub_candidates(osa: sf_record)

    allow_any_instance_of(offering.class).to receive(:ecosystem).and_raise(NoMethodError)

    expect {
      ImportSalesforceCourses.call rescue NoMethodError
    }.to change{Entity::Course.count}.by(0)
  end

  context '#candidate_term_years_array' do
    it 'handles blankness' do
      allow(Settings::Salesforce).to receive(:term_years_to_import) { '' }
      expect(described_class.new.candidate_term_years_array).to eq ['exclude all']
    end

    it 'handles multiple' do
      allow(Settings::Salesforce).to(
        receive(:term_years_to_import) { ' 2015 - 16 Spring, 2016 - 17 Fall ' }
      )
      expect(described_class.new.candidate_term_years_array).to(
        eq ['2015 - 16 Spring', '2016 - 17 Fall']
      )
    end
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
