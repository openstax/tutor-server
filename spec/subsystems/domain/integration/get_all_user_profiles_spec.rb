require 'rails_helper'

describe Domain::GetAllUserProfiles do
  context "when there are multiple users in the system" do
    it "returns an array containing those user's profiles" do
      user1 = FactoryGirl.create(:user, full_name: 'User1')
      user2 = FactoryGirl.create(:user, full_name: 'User2')
      result = Domain::GetAllUserProfiles.call

      expect(result.errors).to be_empty
      expect(result.outputs.profiles.size).to eq(2)
      expect(result.outputs.profiles).to include({ profile_id: user1.id,
                                                   entity_user_id: user1.entity_user_id,
                                                   full_name: 'User1' })
      expect(result.outputs.profiles).to include({ profile_id: user2.id,
                                                   entity_user_id: user2.entity_user_id,
                                                   full_name: 'User2' })
    end
  end
end
