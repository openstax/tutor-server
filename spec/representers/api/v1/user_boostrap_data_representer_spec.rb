require 'rails_helper'

RSpec.describe Api::V1::UserBootstrapDataRepresenter, type: :representer do

  let(:user)           { FactoryGirl.create(:user) }
  let(:representation) { described_class.new(user).as_json }

  it "generates a JSON representation of data for a user to start work with" do
    expect(representation).to eq(
      "user" =>  Api::V1::UserRepresenter.new(user).as_json,
      "courses" => [] # not testing this since it's too expensive to generate meaningful course data
    )
  end

end
