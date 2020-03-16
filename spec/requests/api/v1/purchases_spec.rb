require 'rails_helper'
require 'vcr_helper'

RSpec.describe 'Purchase endpoints', type: :request, api: true, version: :v1, vcr: VCR_OPTS do
  set_vcr_config_around(:all, ignore_localhost: false)

  let(:application)   { FactoryBot.create :doorkeeper_application }

  let(:course)        { FactoryBot.create :course_profile_course }
  let(:period)        { FactoryBot.create :course_membership_period, course: course }

  let(:student_user)  { FactoryBot.create(:user_profile) }
  let(:student_role)  { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)      { student_role.student }
  let(:student_token) do
    FactoryBot.create(
      :doorkeeper_access_token, application: application, resource_owner_id: student_user.id
    )
  end

  before(:all) do
    @original_client = OpenStax::Payments::Api.client
    OpenStax::Payments::Api.use_real_client
    OpenStax::Payments::Api.save_static_client!
    @uuids = vcr_friendly_uuids(count: 10, namespace: "purchase_endpoints")
  end

  after(:all) do
    OpenStax::Payments::Api.client = @original_client
    OpenStax::Payments::Api.save_static_client!
  end

  # Make sure each test run gets fresh, VCR-friendly UUIDs
  before do
    student.update_column(:uuid, @uuids.shift)
    student_user.account.update_column(:uuid, @uuids.shift)
  end

  it 'works through a sequence of purchases and refunds' do
    # Need to time travel to when cassette recorded so we can see if times are recorded
    # as we expect. https://relishapp.com/vcr/vcr/docs/cassettes/freezing-time
    Timecop.travel(VCR.current_cassette.try(:originally_recorded_at) || Time.now) do
      # Make sure start unpaid and no purchases on payments
      expect(student).not_to be_is_paid
      expect(student.first_paid_at).to be_nil
      api_get('/api/purchases', student_token)
      expect(response.body_as_hash[:orders].length).to eq 0

      # First time purchasing
      make_purchase(product_instance_uuid: student.uuid, purchaser_account_uuid: student_user.uuid)
      student.reload
      expect(student).to be_is_paid
      expect(student.first_paid_at).to be_within(1.minute).of(Time.now)
      first_paid_at = student.first_paid_at

      # TODO test student can list orders, requires `make_purchase` to be
      # able to take the purchaser_account_uuid

      api_get('/api/purchases', student_token)
      expect(response.body_as_hash[:orders].length).to eq 1

      # Trigger a refund; Payments will call `check` after the refund completes,
      # so we simulate that call.
      api_put("/api/purchases/#{student.uuid}/refund", student_token)
      api_put("/api/purchases/#{student.uuid}/check", nil)
      student.reload
      expect(student).not_to be_is_paid
      expect(student.first_paid_at).to eq first_paid_at

      # For giggles, let's purchase again and check that first_paid_at still same
      make_purchase(product_instance_uuid: student.uuid)
      student.reload
      expect(student).to be_is_paid
      expect(student.first_paid_at).to eq first_paid_at
    end
  end

  def make_purchase(product_instance_uuid: nil, purchaser_account_uuid: nil)
    # Making a fake purchase on payments should trigger a callback
    # to Tutor to have Tutor come and check the payment status.  We
    # make that call manually here since it is hard/impossible to
    # configure our payments server to call back into this spec
    fake_purchase_response = OpenStax::Payments::Api.client.make_fake_purchase(
      product_instance_uuid: product_instance_uuid,
      purchaser_account_uuid: purchaser_account_uuid
    )

    # Make sure fake purchase actually went through
    expect(fake_purchase_response[:success]).to eq true

    api_put("/api/purchases/#{student.uuid}/check", nil)
    expect(response).to have_http_status(:accepted)
  end
end
