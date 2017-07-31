require 'rails_helper'

RSpec.describe Admin::CoursesRemoveSalesforce, type: :handler do
  let(:course)   { FactoryGirl.create :course_profile_course }
  let(:period_1) { FactoryGirl.create :course_membership_period, course: course }
  let(:period_2) { FactoryGirl.create :course_membership_period, course: course }

  it 'freaks out if there is nothing to remove' do
    expect(
      call(course_id: course.id, salesforce_id: 'whatever')
    ).to have_routine_error(:no_salesforce_matches_for_this_course)
  end

  it 'freaks out with rollback if stats not cleared' do
    fake_sf_object = OpenStruct.new(id: 'fakeid', save: false)
    [course, period_1, period_2].each do |tutor_object|
      FactoryGirl.create(:salesforce_attached_record, tutor_object: tutor_object,
                                                      salesforce_object: fake_sf_object)
    end
    allow_any_instance_of(Salesforce::Models::AttachedRecord)
      .to receive(:salesforce_object) { fake_sf_object }

    expect(
      call(course_id: course.id, salesforce_id: 'fakeid')
    ).to have_routine_error(:could_not_clear_salesforce_stats)

    # no removals stick...
    expect(Salesforce::Models::AttachedRecord.without_deleted.count).to eq 3
  end

  it 'removes and resets stats' do
    disable_sfdc_client

    fake_sf_object_1 = fake_sf_object(klass: OpenStax::Salesforce::Remote::ClassSize, id: 'earlier')
    fake_sf_object_1.num_students = 42
    fake_sf_object_2 = fake_sf_object(klass: OpenStax::Salesforce::Remote::OsAncillary, id: 'later')
    fake_sf_object_2.num_students = 38

    [course, period_1].each do |tutor_object|
      FactoryGirl.create(:salesforce_attached_record, tutor_object: tutor_object,
                                                      salesforce_object: fake_sf_object_1)
    end

    [course, period_2].each do |tutor_object|
      FactoryGirl.create(:salesforce_attached_record, tutor_object: tutor_object,
                                                      salesforce_object: fake_sf_object_2)
    end

    expect{
      call(course_id: course.id, salesforce_id: 'earlier')
    }.to change{Salesforce::Models::AttachedRecord.without_deleted.count}.by(-2)

    expect(Salesforce::Models::AttachedRecord.without_deleted.map(&:tutor_gid))
      .to contain_exactly(course.to_global_id.to_s, period_2.to_global_id.to_s)

    # Course AR should be soft deleted, period AR should be really deleted
    expect(Salesforce::Models::AttachedRecord.all.map(&:tutor_gid))
      .to contain_exactly(course.to_global_id.to_s, course.to_global_id.to_s,
                          period_2.to_global_id.to_s)

    expect(fake_sf_object_1.num_students).to eq 0
    expect(fake_sf_object_2.num_students).to eq 38
  end

  it 'does not explode if the SF object is no longer in SF' do
    disable_sfdc_client

    FactoryGirl.create(:salesforce_attached_record,
                       tutor_object: course,
                       salesforce_class_name: "OpenStax::Salesforce::Remote::ClassSize",
                       salesforce_id: "something",
                       salesforce_object: nil)

    allow(OpenStax::Salesforce::Remote::ClassSize).to receive(:find).with("something") { nil }

    expect{
      call(course_id: course.id, salesforce_id: 'something')
    }.not_to raise_error
  end

  it "can find the methods it needs in potential SF object classes" do
    # Have this check since we're mostly otherwise stubbing these classes
    [OpenStax::Salesforce::Remote::OsAncillary, OpenStax::Salesforce::Remote::ClassSize].each do |sf_class|
      expect(sf_class.new).to respond_to(:reset_stats, :save)
    end
  end

  def fake_sf_object(klass:, id:, save_outcome: true)
    klass.new(id: id).tap do |fake|
      allow(fake).to receive(:save) { save_outcome }   # stub save
      allow(klass).to receive(:find).with(id) { fake } # let lookup work
    end
  end

  def call(course_id:, salesforce_id:)
    described_class.handle(params: {
      id: course_id, remove_salesforce: { salesforce_id: salesforce_id }
    })
  end

end
