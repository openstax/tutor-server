require 'rails_helper'

RSpec.describe Admin::CoursesAddSalesforce, type: :handler do
  let(:course) { FactoryBot.create :course_profile_course }

  it 'freaks out if the SF object does not exist' do
    allow_any_instance_of(described_class).to receive(:get_salesforce_object_for_id) { nil }
    call(course_id: course.id, salesforce_id: 'does not matter')
  end

  context 'when the SF object exists' do
    let(:sf_object) { OpenStruct.new(id: 'fakeid') }

    before(:each) do
      allow_any_instance_of(described_class).to receive(:get_salesforce_object_for_id)
                                            .with('fakeid') {
                                              sf_object
                                            }
    end

    it 'adds to a course without any SF object' do
      result = nil
      expect{
        result = call(course_id: course.id, salesforce_id: 'fakeid')
      }.to change{Salesforce::Models::AttachedRecord.count}.by(1)
      expect(result.errors).to be_empty
    end

    it 'adds to a course already with an SF object' do
      FactoryBot.create(:salesforce_attached_record,
                         tutor_object: course,
                         salesforce_object: OpenStruct.new(id: 'some other SF object'))
      result = nil
      expect{
        result = call(course_id: course.id, salesforce_id: sf_object.id)
      }.to change{Salesforce::Models::AttachedRecord.count}.by(1)
      expect(result.errors).to be_empty
    end

    it 'freaks out if this specific SF record already linked' do
      FactoryBot.create(:salesforce_attached_record,
                         tutor_object: course,
                         salesforce_object: sf_object)
      expect(
        call(course_id: course.id, salesforce_id: sf_object.id)
      ).to have_routine_error(:course_and_salesforce_object_already_attached)
    end
  end

  def call(course_id:, salesforce_id:)
    described_class.handle(params: {
      id: course_id, add_salesforce: { salesforce_id: salesforce_id }
    })
  end

end
