RSpec.describe Assistant, :type => :model do
  xit { is_expected.to belong_to(:study) } # Study NYI

  it { is_expected.to have_many(:task_plans) }

  it { is_expected.to validate_presence_of(:code_class_name) }
end
