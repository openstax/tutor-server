require 'rails_helper'

RSpec.describe School, :type => :model do

  it 'must have a name' do
    expect(School.new()).to_not be_valid
  end



end
