RSpec.describe Assistant, :type => :model do
  subject { FactoryGirl.create :assistant }

  it { is_expected.to have_many(:course_assistants).dependent(:destroy) }
  it { is_expected.to have_many(:task_plans).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:code_class_name) }
  it { is_expected.to validate_presence_of(:task_plan_type) }

  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_uniqueness_of(:code_class_name) }

  xit 'validates the presence of the code class' do
  end
end
