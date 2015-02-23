require 'rails_helper'

RSpec.describe TaskAccessPolicy do
  let(:requestor) { FactoryGirl.create(:user) }
  let(:task) { FactoryGirl.create(:task) }

  [:create, :update, :destroy, :made_up].each do |disallowed_action|
    context "when the action is #{disallowed_action}" do
      it 'is not allowed' do
          expect(TaskAccessPolicy).not_to be_action_allowed(disallowed_action,
                                                            requestor,
                                                            task)
      end
    end
  end
end
