require 'rails_helper'

RSpec.describe Tasks::Models::TaskPageCache, type: :model do
  subject(:task_page_cache) { FactoryGirl.create :tasks_task_page_cache }

  it { is_expected.to belong_to(:task)    }
  it { is_expected.to belong_to(:student) }
  it { is_expected.to belong_to(:page)    }

  it { is_expected.to validate_presence_of(:task)    }
  it { is_expected.to validate_presence_of(:student) }
  it { is_expected.to validate_presence_of(:page)    }

  it { is_expected.to validate_presence_of(:num_assigned_exercises)  }
  it { is_expected.to validate_presence_of(:num_completed_exercises) }
  it { is_expected.to validate_presence_of(:num_correct_exercises)   }

  it do
    is_expected.to(
      validate_uniqueness_of(:task).scoped_to(:course_membership_student_id, :content_page_id)
    )
  end

  it { is_expected.to validate_numericality_of(:num_assigned_exercises).only_integer  }
  it { is_expected.to validate_numericality_of(:num_completed_exercises).only_integer }
  it { is_expected.to validate_numericality_of(:num_correct_exercises).only_integer   }
end
