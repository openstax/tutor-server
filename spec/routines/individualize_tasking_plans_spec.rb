require 'rails_helper'

RSpec.describe IndividualizeTaskingPlans, type: :routine do

  let(:task_plan)    { FactoryGirl.create :tasks_task_plan }
  let(:tasking_plan) { task_plan.tasking_plans.first }

  let(:result)       { described_class[task_plan: task_plan] }
  let(:ts_result)    { described_class[task_plan: task_plan, role_type: :teacher_student] }

  context 'entity_role' do
    let(:role)  { FactoryGirl.create :entity_role }

    before      { tasking_plan.update_attribute(:target, role) }

    it 'returns a tasking plan with the exact same attributes' do
      expect(result.size).to eq 1

      new_tasking_plan = result.first

      expect(new_tasking_plan.task_plan).to eq task_plan
      expect(new_tasking_plan.target).to eq tasking_plan.target
      expect(new_tasking_plan.opens_at).to be_within(1e-6).of tasking_plan.opens_at
      expect(new_tasking_plan.due_at).to be_within(1e-6).of tasking_plan.due_at
    end
  end

  context 'user_profile' do
    let(:profile)      { FactoryGirl.create :user_profile }
    let(:user)         { ::User::User.new(strategy: profile.wrap) }
    let(:default_role) { Role::GetDefaultUserRole[user] }

    before do
      tasking_plan.update_attribute(:target, profile)
    end

    it 'returns a tasking plan pointing to the user\'s default role' do
      expect(result.size).to eq 1

      new_tasking_plan = result.first

      expect(new_tasking_plan.task_plan).to eq task_plan
      expect(new_tasking_plan.target).to eq default_role
      expect(new_tasking_plan.opens_at).to be_within(1e-6).of tasking_plan.opens_at
      expect(new_tasking_plan.due_at).to be_within(1e-6).of tasking_plan.due_at
    end
  end

  context 'course_profile_course' do
    let(:period_1)               { FactoryGirl.create :course_membership_period }
    let(:course)                 { period_1.course }
    let(:period_2)               { FactoryGirl.create :course_membership_period, course: course }

    let(:teacher_student_role_1) { period_1.teacher_student_role }
    let(:teacher_student_role_2) { period_2.teacher_student_role }

    let(:user_1)                 { FactoryGirl.create :user }
    let(:user_2)                 { FactoryGirl.create :user }
    let(:user_3)                 { FactoryGirl.create :user }

    let!(:student_role_1)        { AddUserAsPeriodStudent[user: user_1, period: period_1] }
    let!(:student_role_2)        { AddUserAsPeriodStudent[user: user_2, period: period_1] }
    let!(:student_role_3)        { AddUserAsPeriodStudent[user: user_3, period: period_2] }

    before                       { tasking_plan.update_attribute(:target, course) }

    it 'returns tasking plans pointing to the course\'s student and teacher_student roles' do
      expect(result.size).to eq 5
      acceptable_roles = [student_role_1, student_role_2, student_role_3,
                          teacher_student_role_1, teacher_student_role_2]

      result.each do |new_tasking_plan|
        expect(new_tasking_plan.task_plan).to eq task_plan
        expect(new_tasking_plan.target).to be_in acceptable_roles
        expect(new_tasking_plan.opens_at).to be_within(1e-6).of tasking_plan.opens_at
        expect(new_tasking_plan.due_at).to be_within(1e-6).of tasking_plan.due_at
      end
    end

    it 'limits results to the specified role_type, if given' do
      expect(ts_result.size).to eq 2
      acceptable_roles = [teacher_student_role_1, teacher_student_role_2]

      ts_result.each do |new_tasking_plan|
        expect(new_tasking_plan.task_plan).to eq task_plan
        expect(new_tasking_plan.target).to be_in acceptable_roles
        expect(new_tasking_plan.opens_at).to be_within(1e-6).of tasking_plan.opens_at
        expect(new_tasking_plan.due_at).to be_within(1e-6).of tasking_plan.due_at
      end
    end

    it 'returns no results for periods that have been deleted' do
      period_1.delete
      task_plan.reload
      tasking_plan.reload

      expect(result.size).to eq 2

      new_tasking_plan = result.first

      expect(new_tasking_plan.task_plan).to eq task_plan
      expect(new_tasking_plan.target).to eq student_role_3
      expect(new_tasking_plan.opens_at).to be_within(1e-6).of tasking_plan.opens_at
      expect(new_tasking_plan.due_at).to be_within(1e-6).of tasking_plan.due_at
    end
  end

  context 'course_membership_period' do
    let(:period_1)               { FactoryGirl.create :course_membership_period }
    let(:course)                 { period_1.course }
    let(:period_2)               { FactoryGirl.create :course_membership_period, course: course }

    let(:teacher_student_role_1) { period_1.teacher_student_role }

    let(:user_1)                 { FactoryGirl.create :user }
    let(:user_2)                 { FactoryGirl.create :user }
    let(:user_3)                 { FactoryGirl.create :user }

    let!(:student_role_1)        { AddUserAsPeriodStudent[user: user_1, period: period_1] }
    let!(:student_role_2)        { AddUserAsPeriodStudent[user: user_2, period: period_1] }
    let!(:student_role_3)        { AddUserAsPeriodStudent[user: user_3, period: period_2] }

    before                       { tasking_plan.update_attribute(:target, period_1) }

    it 'returns tasking plans pointing to the period\'s student and teacher_student roles' do
      expect(result.size).to eq 3
      acceptable_roles = [student_role_1, student_role_2, teacher_student_role_1]

      result.each do |new_tasking_plan|
        expect(new_tasking_plan.task_plan).to eq task_plan
        expect(new_tasking_plan.target).to be_in acceptable_roles
        expect(new_tasking_plan.opens_at).to be_within(1e-6).of tasking_plan.opens_at
        expect(new_tasking_plan.due_at).to be_within(1e-6).of tasking_plan.due_at
      end
    end

    it 'limits results to the specified role_type, if given' do
      expect(ts_result.size).to eq 1
      acceptable_roles = [teacher_student_role_1]

      ts_result.each do |new_tasking_plan|
        expect(new_tasking_plan.task_plan).to eq task_plan
        expect(new_tasking_plan.target).to be_in acceptable_roles
        expect(new_tasking_plan.opens_at).to be_within(1e-6).of tasking_plan.opens_at
        expect(new_tasking_plan.due_at).to be_within(1e-6).of tasking_plan.due_at
      end
    end

    it 'returns no results if the period has been deleted' do
      period_1.delete
      task_plan.reload

      expect(result).to be_empty
    end

    it 'does not create tasking plans for dropped students' do
      CourseMembership::InactivateStudent[student: student_role_2.student]
      expect(result.first.target_id).to eq student_role_1.id
    end
  end

end
