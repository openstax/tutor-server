require 'rails_helper'

describe Content::Ecosystem::Ecosystem do

  context "construction" do
    it "accepts a strategy object" do
      expect{
        Content::Ecosystem::Ecosystem.new(strategy: Object.new)
        }.to_not raise_error
    end
  end

  context "fetching books" do
  end

end
