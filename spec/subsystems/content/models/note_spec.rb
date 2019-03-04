require 'rails_helper'

RSpec.describe Content::Models::Note, type: :model do

  subject(:note) { FactoryBot.create :content_note }

  it "factory creates records" do
    expect(subject).not_to be_new_record
  end

end
