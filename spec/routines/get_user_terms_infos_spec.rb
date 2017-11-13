require 'rails_helper'

RSpec.describe GetUserTermsInfos, type: :routine do

  let(:user) { FactoryBot.create(:user) }

  it 'does not explode if standard terms are absent' do
    expect{described_class[user]}.not_to raise_error
  end

  context "normal flow" do
    let(:period) { FactoryBot.create :course_membership_period }
    before {
      AddUserAsPeriodStudent[period: period, user: user]
      create_contract!('general_terms_of_use')
      create_contract!('privacy_policy')
      create_contract!('implicit')
      Legal::CreateTargetedContract[
        contract_name: 'implicit',
        target_gid: period.course.to_global_id.to_s, target_name: 'whatev',
        is_proxy_signed: true
      ]
    }

    it 'signs proxy signed contracts' do
      expect{
        described_class[user]
      }.to change{
        FinePrint.signed_contract?(user.to_model, 'implicit')
      }.from(false).to(true)
    end

    it 'indicates if terms signed before' do
      version_1 = FinePrint.sign_contract(user.to_model, 'privacy_policy').contract
      version_2 = version_1.new_version
      version_2.content = 'howdy'
      version_2.publish

      expect(described_class[user]).to match a_collection_including(
        a_hash_including(
          name: 'privacy_policy',
          title: 'privacy_policy title',
          content: 'howdy',
          version: 2,
          is_signed: false,
          has_signed_before: true,
          is_proxy_signed: false
        )
      )
    end

    it 'includes all expected output' do
      expect(described_class[user]).to match a_collection_containing_exactly(
        a_hash_including(
          name: 'general_terms_of_use',
          title: 'general_terms_of_use title',
          content: 'general_terms_of_use content',
          version: 1,
          is_signed: false,
          has_signed_before: false,
          is_proxy_signed: false
        ),
        a_hash_including(
          name: 'privacy_policy',
          title: 'privacy_policy title',
          content: 'privacy_policy content',
          version: 1,
          is_signed: false,
          has_signed_before: false,
          is_proxy_signed: false
        ),
        a_hash_including(
          name: 'implicit',
          title: 'implicit title',
          content: 'implicit content',
          version: 1,
          is_signed: true,
          has_signed_before: true,
          is_proxy_signed: true
        )
      )
    end

  end

end
