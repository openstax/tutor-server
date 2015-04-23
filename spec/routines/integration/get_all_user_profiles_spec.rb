require 'rails_helper'

describe GetAllUserProfiles do
  context "when there are multiple users in the system" do
    it "returns an array containing those user's profiles" do
      user1 = FactoryGirl.create(:user_profile, username: 'Username1', full_name: 'User1')
      user2 = FactoryGirl.create(:user_profile, username: 'Username2', full_name: 'User2')
      result = GetAllUserProfiles.call

      expect(result.errors).to be_empty
      expect(result.outputs.profiles.size).to eq(2)
      expect(result.outputs.profiles).to include({ id: user1.id,
                                                   account_id: user1.account_id,
                                                   entity_user_id: user1.entity_user_id,
                                                   full_name: 'User1',
                                                   username: 'Username1' })
      expect(result.outputs.profiles).to include({ id: user2.id,
                                                   account_id: user2.account_id,
                                                   entity_user_id: user2.entity_user_id,
                                                   full_name: 'User2',
                                                   username: 'Username2' })
    end
  end
end
