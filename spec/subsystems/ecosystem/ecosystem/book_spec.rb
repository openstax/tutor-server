require 'rails_helper'

module Ecosystem
  describe Book do

    context "construction" do
      it "accepts a strategy" do
        expect{
          ::Ecosystem::Book.new(strategy: Object.new)
        }.to_not raise_error
      end
    end

  end
end
