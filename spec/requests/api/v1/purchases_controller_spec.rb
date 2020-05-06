require 'rails_helper'

RSpec.describe Api::V1::PurchasesController, type: :request, api: true,
                                             version: :v1, vcr: VCR_OPTS do
  let(:application)       { FactoryBot.create :doorkeeper_application }

  let(:period)            { FactoryBot.create :course_membership_period }

  let(:student_user)      { FactoryBot.create(:user_profile) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }
  let(:student_token)     { FactoryBot.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: student_user.id }

  let(:other_user)        { FactoryBot.create(:user_profile) }
  let(:other_user_token)  { FactoryBot.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: other_user.id }

  context '#index' do
    it 'returns JSON from payments' do
      expect(OpenStax::Payments::Api.client).to(
        receive(:orders_for_account)
          .with(student_user.account)
          .and_return(orders: [1, 2, 3])
      )
      api_get api_purchases_url, student_token
      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash).to eq(orders: [1, 2, 3])
    end
  end

  context '#check' do
    let(:limit) { 10 }

    it 'gives accepted status when the student exists' do
      student = FactoryBot.create(:course_membership_student)
      expect(UpdatePaymentStatus).to receive(:perform_later).with(uuid: student.uuid)
      api_put check_api_purchase_url(student.uuid), nil
      expect(response).to have_http_status(:accepted)
    end

    it 'gives not found status when the student does not exist' do
      api_put check_api_purchase_url('some UUID'), nil
      expect(response).to have_http_status(:not_found)
    end

    it 'allows requests under the limit, throttles at limit, and logs only once, all based on ID' do
      # Allowed
      limit.times do
        api_put check_api_purchase_url('first_ID'), nil
        expect(response).to_not have_http_status(429)
      end

      # First to pass the limit
      expect_any_instance_of(Rack::Attack::Request).to receive(:log_throttled!).once
      api_put check_api_purchase_url('first_ID'), nil
      expect(response).to have_http_status(429)

      # Second to pass the limit
      api_put check_api_purchase_url('first_ID'), nil
      expect(response).to have_http_status(429)

      # Different IP OK
      api_put check_api_purchase_url('second_ID'), nil
      expect(response).to_not have_http_status(429)
    end
  end

  context '#refund' do
    it 'gives not found status when the student does not exist' do
      api_put refund_api_purchase_url('some UUID'), student_token
      expect(response).to have_http_status(:not_found)
    end

    it 'gives 403 when user does not own student' do
      expect do
        api_put refund_api_purchase_url(student.uuid), other_user_token
      end.to raise_error(SecurityTransgression)
    end

    it 'gives 422 not paid if not paid' do
      api_put refund_api_purchase_url(student.uuid), student_token
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors]).to match a_collection_containing_exactly(
        a_hash_including(code: 'not_paid')
      )
    end

    it 'gives 422 if paid too long ago' do
      Timecop.freeze(Time.now - 14.days - 2.hours) do
        student.update_attributes!(is_paid: true)
      end
      api_put refund_api_purchase_url(student.uuid), student_token
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors]).to match a_collection_containing_exactly(
        a_hash_including(code: 'refund_period_elapsed')
      )
    end

    it 'gives 202 accepted if all good' do
      student.update_attributes!(is_paid: true)

      survey_params = { 'why' => 'too-expensive', 'comments' => 'gimme my money back' }
      expect(RefundPayment).to receive(:perform_later) do |uuid:, survey:|
        expect(uuid).to eq student.uuid
        expect(survey.to_h).to eq survey_params
      end
      api_put refund_api_purchase_url(student.uuid, survey: survey_params), student_token
      expect(response).to have_http_status(:accepted)
    end
  end

  context '#create_fake' do
    it 'creates new fake purchased items' do
      uuids = 2.times.map { SecureRandom.uuid }
      api_post fake_api_purchases_url, nil, params: uuids.to_json
      expect(OpenStax::Payments::FakePurchasedItem.find(uuids[0])).to be_present
      expect(OpenStax::Payments::FakePurchasedItem.find(uuids[1])).to be_present
    end
  end

  context 'purchase endpoints' do
    set_vcr_config_around(:all, ignore_localhost: false)

    before(:all) do
      @original_client = OpenStax::Payments::Api.client
      OpenStax::Payments::Api.use_real_client
      OpenStax::Payments::Api.save_static_client!
      @uuids = vcr_friendly_uuids(count: 10, namespace: 'purchase_endpoints')
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

      api_put(check_api_purchase_url(student.uuid), nil)
      expect(response).to have_http_status(:accepted)
    end

    it 'works through a sequence of purchases and refunds' do
      # Need to time travel to when cassette recorded so we can see if times are recorded
      # as we expect. https://relishapp.com/vcr/vcr/docs/cassettes/freezing-time
      Timecop.travel(VCR.current_cassette.try(:originally_recorded_at) || Time.now) do
        # Make sure start unpaid and no purchases on payments
        expect(student).not_to be_is_paid
        expect(student.first_paid_at).to be_nil
        api_get(api_purchases_url, student_token)
        expect(response.body_as_hash[:orders].length).to eq 0

        # First time purchasing
        make_purchase(product_instance_uuid: student.uuid, purchaser_account_uuid: student_user.uuid)
        student.reload
        expect(student).to be_is_paid
        expect(student.first_paid_at).to be_within(1.minute).of(Time.now)
        first_paid_at = student.first_paid_at

        # TODO test student can list orders, requires `make_purchase` to be
        # able to take the purchaser_account_uuid

        api_get(api_purchases_url, student_token)
        expect(response.body_as_hash[:orders].length).to eq 1

        # Trigger a refund; Payments will call `check` after the refund completes,
        # so we simulate that call.
        api_put(refund_api_purchase_url(student.uuid), student_token)
        api_put(check_api_purchase_url(student.uuid), nil)
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
  end
end
