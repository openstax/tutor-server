require 'rails_helper'

RSpec.describe ActsAsResource do
  [:page, :exercise].each do |class_name|
    context class_name do
      subject(:r) { FactoryGirl.create class_name }

      it { is_expected.to validate_presence_of(:url) }

      it { is_expected.to validate_uniqueness_of(:url) }
    end
  end

  context 'book' do
    subject(:book) { FactoryGirl.create :book }

    it { is_expected.not_to validate_presence_of(:url) }

    it { is_expected.to validate_uniqueness_of(:url).allow_nil }
  end
end
