require 'rails_helper'

module Cc
  RSpec.describe TaskAccessPolicy, type: :access_policy do
    let(:requestor) { FactoryGirl.create(:user) }

    subject(:action_allowed) do
      described_class.action_allowed?(action, requestor, Tasks::Models::ConceptCoachTask)
    end

    context "when the action is show" do
      let(:action) { :show }

      context 'and the requestor is anonymous' do
        before { allow(requestor).to receive(:is_anonymous?) { true } }

        it { should be false }
      end

      context 'and the requestor is not human' do
        before { allow(requestor).to receive(:is_human?) { false } }

        it { should be false }
      end

      context 'and the requestor is a normal user' do
        it { should be true }
      end
    end

    context "when the action is made_up" do
      let(:action) { :made_up }

      it { should be false }
    end
  end
end
