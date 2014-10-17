require 'rails_helper'

RSpec.describe Student, :type => :model do
  it { is_expected.to belong_to(:klass) }
  it { is_expected.to belong_to(:section) }

  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:klass) }

  it 'must generate a random education identifier' do
    student = FactoryGirl.create(:student, random_education_identifier: nil)
    expect(student.random_education_identifier).not_to be_blank
  end
  
  it 'must enforce that one student is only in one section once' do
    # should-matcher uniqueness validations don't work on associations http://goo.gl/EcC1LQ
    # it { is_expected.to validate_uniqueness_of(:section).scoped_to(:user_id).allow_nil } 

    section = FactoryGirl.create(:section)
    student1 = FactoryGirl.create(:student, section: section)
    student2 = FactoryGirl.build(:student, user: student1.user,
                                           section: section)
    expect(student2).to_not be_valid
  end

  it 'must enforce that one student is only in one klass once' do
    student1 = FactoryGirl.create(:student)
    student2 = FactoryGirl.build(:student, user: student1.user,
                                           klass: student1.klass)
    expect(student2).to_not be_valid
  end

  it 'must have a section that matches the klass' do
    section = FactoryGirl.create(:section)
    other_klass = FactoryGirl.create(:klass)

    student = FactoryGirl.create(:student)
    student.section = FactoryGirl.create(:section)
    expect(student).to_not be_valid
  end

  it 'must enforce the uniqueness of random_education_identifiers' do
    student1 = FactoryGirl.create(:student)
    student2 = FactoryGirl.create(:student)
    student2.random_education_identifier = student1.random_education_identifier
    expect(student2).to_not be_valid
  end

  it 'must not allow user to be changed after creation' do
    student = FactoryGirl.create(:student)
    student.user = FactoryGirl.build(:user)
    expect(student).to_not be_valid
  end
end
