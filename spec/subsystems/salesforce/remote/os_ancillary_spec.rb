require 'rails_helper'

RSpec.describe Salesforce::Remote::OsAncillary do

  context 'when product is Concept Coach' do
    subject { described_class.new(product: "Concept Coach") }

    it { is_expected.to be_is_concept_coach }
    it { is_expected.not_to be_is_tutor }
    it { is_expected.to be_valid_product }
  end

  context 'when product is Tutor' do
    subject { described_class.new(product: "Tutor") }

    it { is_expected.not_to be_is_concept_coach }
    it { is_expected.to be_is_tutor }
    it { is_expected.to be_valid_product }
  end

  context 'when product is nil' do
    subject { described_class.new }

    it { is_expected.not_to be_is_concept_coach }
    it { is_expected.not_to be_is_tutor }
    it { is_expected.not_to be_valid_product }
  end

  it 'knows which account types are for college' do
    described_class::COLLEGE_ACCOUNT_TYPES.each do |college_type|
      expect(described_class.new(account_type: college_type)).to be_is_college
    end
  end

end
