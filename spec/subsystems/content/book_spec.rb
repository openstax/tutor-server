require 'rails_helper'

module Content
  RSpec.describe Book do

    context "construction" do
      it "accepts a strategy" do
        expect{
          ::Content::Book.new(strategy: Object.new)
        }.to_not raise_error
      end
    end

  end
end
