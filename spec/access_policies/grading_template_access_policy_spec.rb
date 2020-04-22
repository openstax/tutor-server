require 'rails_helper'

RSpec.describe GradingTemplateAccessPolicy, type: :access_policy do
  let(:grading_template)   { FactoryBot.create :tasks_grading_template }
  let(:course)             { grading_template.course }

  subject(:action_allowed) { described_class.action_allowed?(action, requestor, grading_template) }

  context 'anonymous user' do
    let(:requestor) { User::Models::AnonymousProfile.instance }

    [ :index, :create, :read, :update, :destroy ].each do |action|
      context "##{action}" do
        let(:action) { action }

        it 'cannot be accessed' do
          expect(action_allowed).to eq false
        end
      end
    end
  end

  context 'any user' do
    let(:requestor) { FactoryBot.create :user_profile }

    [ :index, :create ].each do |action|
      context "##{action}" do
        let(:action) { action }

        it 'can be accessed' do
          expect(action_allowed).to eq true
        end
      end
    end

    [ :read, :update, :destroy ].each do |action|
      context "##{action}" do
        let(:action) { action }

        it 'cannot be accessed' do
          expect(action_allowed).to eq false
        end
      end
    end
  end

  context 'teacher user' do
    let(:requestor) { FactoryBot.create :user_profile }

    before { AddUserAsCourseTeacher[user: requestor, course: course] }

    [ :index, :create, :read, :update, :destroy ].each do |action|
      context "##{action}" do
        let(:action) { action }

        it 'can be accessed' do
          expect(action_allowed).to eq true
        end
      end
    end
  end
end
