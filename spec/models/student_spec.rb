require 'rails_helper'

RSpec.describe Student, :type => :model do
  it { is_expected.to belong_to(:course) }
  it { is_expected.to belong_to(:section) }

  it { is_expected.to have_many(:taskings).dependent(:destroy) }
  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:course) }
  it { is_expected.to validate_presence_of(:random_education_identifier) }
  
  it 'must enforce that one student is only in one section once' do
    # should-matcher uniqueness validations don't work on associations http://goo.gl/EcC1LQ
    # it { is_expected.to validate_uniqueness_of(:section).scoped_to(:user_id).allow_nil } 

    student1 = FactoryGirl.create(:student)
    student2 = FactoryGirl.create(:student)
    student2.section = student1.section
    expect(student2).to_not be_valid
  end

  it 'must enforce that no student is in a course more than once' do
    student1 = FactoryGirl.create(:student)
    student2 = FactoryGirl.create(:student)
    student2.course = student1.course
    expect(student2).to_not be_valid
  end

  it 'must have a section that matches the course' do
    student = FactoryGirl.create(:student)
    expect(student).to be_persisted
    student.section = FactoryGirl.create(:section)
    expect(student).to_not be_valid
  end

  it 'must enforce the uniqueness of random_education_identifiers' do
    student1 = FactoryGirl.create(:student)
    student2 = FactoryGirl.create(:student)
    student2.random_education_identifier = student1.random_education_identifier
    expect(student2).to_not be_valid
  end
end
