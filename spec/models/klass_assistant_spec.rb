require 'rails_helper'

RSpec.describe KlassAssistant, type: :model do
  subject { FactoryGirl.create :klass_assistant }

  it { is_expected.to belong_to(:klass) }
  it { is_expected.to belong_to(:assistant) }

  it { is_expected.to validate_presence_of(:klass) }
  it { is_expected.to validate_presence_of(:assistant) }

  it { is_expected.to validate_uniqueness_of(:assistant).scoped_to(:klass_id) }
end
