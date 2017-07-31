require 'rails_helper'

RSpec.describe Admin::PeriodsChangeSalesforce, type: :handler do
  let(:course)   { FactoryGirl.create :course_profile_course }
  let(:period_1) { FactoryGirl.create :course_membership_period, course: course }

  it 'freaks out if the requested salesforce ID is not attached to course' do
    expect(
      call(period_id: period_1.id, salesforce_id: 'madeup')
    ).to have_routine_error(:can_only_use_course_salesforce_ids_for_periods)
  end

  it 'freaks out if there are multiple attached records for one period' do
    FactoryGirl.create(:salesforce_attached_record, tutor_object: course,
                                                    salesforce_object: OpenStruct.new(id: 'foo'))
    FactoryGirl.create(:salesforce_attached_record, tutor_object: period_1,
                                                    salesforce_object: OpenStruct.new(id: 'one'))
    FactoryGirl.create(:salesforce_attached_record, tutor_object: period_1,
                                                    salesforce_object: OpenStruct.new(id: 'two'))
    expect(
      call(period_id: period_1.id, salesforce_id: 'foo')
    ).to have_routine_error(:found_unexpected_period_attached_salesforce_records)
  end

  context "when the course has a SF record" do
    before(:each) do
      FactoryGirl.create(:salesforce_attached_record,
                         tutor_object: course,
                         salesforce_object: OpenStruct.new(id: 'foo'))
    end

    context "when the period does not have a SF record yet" do
      it 'works when the incoming SF ID is not blank' do
        expect{
          call(period_id: period_1.id, salesforce_id: 'foo')
        }.to change{Salesforce::Models::AttachedRecord.count}.by(1)

        new_ar = Salesforce::Models::AttachedRecord.all.select do |ar|
          ar.attached_to_class_name == "CourseMembership::Models::Period"
        end.first

        expect(new_ar.salesforce_class_name).to eq "OpenStruct"
        expect(new_ar.salesforce_id).to eq "foo"
      end

      it 'works when the incoming SF ID is blank' do
        expect{
          call(period_id: period_1.id, salesforce_id: '')
        }.not_to change{Salesforce::Models::AttachedRecord.count}
      end
    end

    context "when the period already has a SF record" do
      before(:each) do
        FactoryGirl.create(:salesforce_attached_record,
                           tutor_object: period_1,
                           salesforce_object: OpenStruct.new(id: 'something else'))
      end

      it 'changes the AR\'s ID when the incoming SF ID is not blank' do
        expect(Salesforce::Models::AttachedRecord.where(salesforce_id: 'foo').count).to eq 1

        expect{
          call(period_id: period_1.id, salesforce_id: 'foo')
        }.not_to change{Salesforce::Models::AttachedRecord.count}

        expect(Salesforce::Models::AttachedRecord.where(salesforce_id: 'foo').count).to eq 2
      end

      it 'deletes the existing AR when the incoming SF ID is blank' do
        expect{
          call(period_id: period_1.id, salesforce_id: '')
        }.to change{Salesforce::Models::AttachedRecord.without_deleted.count}.by(-1)
      end
    end
  end

  def call(period_id:, salesforce_id:)
    described_class.handle(params: {
      id: period_id, change_salesforce: { salesforce_id: salesforce_id }
    })
  end

end
