require 'rails_helper'

RSpec.describe Salesforce::RenewOsAncillary do

  xit 'works' do

  end

  it 'can get next TermYear' do
    expect(described_class.next_term_year("2015 - 16 Fall")).to eq "2015 - 16 Spring"
    expect(described_class.next_term_year("2015 - 16 Spring")).to eq "2016 - 17 Fall"
  end
end
