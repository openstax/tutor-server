require 'rails_helper'

RSpec.describe KlassAccessPolicy do
  let!(:anon)           { AnonymousUser.instance }
  let!(:user)           { FactoryGirl.create(:user) }
  let!(:application)    { FactoryGirl.create(:doorkeeper_application) }
  let!(:klass)          { FactoryGirl.build(:klass) }
  let!(:student)        { FactoryGirl.create(:student, klass: klass) }
  let!(:educator)       { FactoryGirl.create(:educator, klass: klass) }
  let!(:course_manager) { FactoryGirl.create(:course_manager, course: klass.course) }
  let!(:school_manager) { FactoryGirl.create(:school_manager, school: klass.school) }
  let!(:administrator)  { FactoryGirl.create(:administrator) }

  context 'index' do
    it 'cannot be accessed by anonymous users or applications' do
      expect(KlassAccessPolicy.action_allowed?(:index, anon, Klass)).to eq false

      expect(KlassAccessPolicy.action_allowed?(:index, application, Klass)).to eq false
    end

    it 'can be accessed by human users' do
      expect(KlassAccessPolicy.action_allowed?(:index, user, Klass)).to eq true
    end
  end

  context 'read' do
    context 'visible' do
      it 'cannot be accessed by anonymous users or applications' do
        expect(KlassAccessPolicy.action_allowed?(:index, anon, klass)).to eq false

        expect(KlassAccessPolicy.action_allowed?(:index, application, klass)).to eq false
      end

      it 'can be accessed by human users' do
        expect(KlassAccessPolicy.action_allowed?(:index, user, klass)).to eq true
      end
    end

    context 'invisible' do
      before(:each) do
        klass.visible_at = Time.now - 2.weeks
        klass.invisible_at = Time.now - 1.week
      end

      it 'cannot be accessed by anonymous users, applications, unrelated users or students' do
        expect(KlassAccessPolicy.action_allowed?(:read, anon, klass)).to eq false

        expect(KlassAccessPolicy.action_allowed?(:read, application, klass)).to eq false

        expect(KlassAccessPolicy.action_allowed?(:read, user, klass)).to eq false

        expect(KlassAccessPolicy.action_allowed?(:read, student.user, klass)).to eq false
      end

      it 'can be accessed by educators, course managers, school managers and administrators' do
        expect(KlassAccessPolicy.action_allowed?(
          :read, educator.user, klass)).to eq true

        expect(KlassAccessPolicy.action_allowed?(
          :read, course_manager.user, klass)).to eq true

        expect(KlassAccessPolicy.action_allowed?(
          :read, school_manager.user, klass)).to eq true

        expect(KlassAccessPolicy.action_allowed?(
          :read, administrator.user, klass)).to eq true
      end
    end
  end

  context 'create and destroy' do
    it 'cannot be accessed by anonymous users, applications, unrelated users, students or educators' do
      expect(KlassAccessPolicy.action_allowed?(:create, anon, klass)).to eq false
      expect(KlassAccessPolicy.action_allowed?(:destroy, anon, klass)).to eq false

      expect(KlassAccessPolicy.action_allowed?(:create, application, klass)).to eq false
      expect(KlassAccessPolicy.action_allowed?(:destroy, application, klass)).to eq false

      expect(KlassAccessPolicy.action_allowed?(:create, user, klass)).to eq false
      expect(KlassAccessPolicy.action_allowed?(:destroy, user, klass)).to eq false

      expect(KlassAccessPolicy.action_allowed?(:create, student.user, klass)).to eq false
      expect(KlassAccessPolicy.action_allowed?(:destroy, student.user, klass)).to eq false

      expect(KlassAccessPolicy.action_allowed?(:create, educator.user, klass)).to eq false
      expect(KlassAccessPolicy.action_allowed?(:destroy, educator.user, klass)).to eq false
    end

    it 'can be accessed by course managers, school managers and administrators' do
      expect(KlassAccessPolicy.action_allowed?(
        :create, course_manager.user, klass)).to eq true
      expect(KlassAccessPolicy.action_allowed?(
        :destroy, course_manager.user, klass)).to eq true

      expect(KlassAccessPolicy.action_allowed?(
        :create, school_manager.user, klass)).to eq true
      expect(KlassAccessPolicy.action_allowed?(
        :destroy, school_manager.user, klass)).to eq true

      expect(KlassAccessPolicy.action_allowed?(
        :create, administrator.user, klass)).to eq true
      expect(KlassAccessPolicy.action_allowed?(
        :destroy, administrator.user, klass)).to eq true
    end
  end

  context 'update' do
    it 'cannot be accessed by anonymous users, applications, unrelated users or students' do
      expect(KlassAccessPolicy.action_allowed?(:update, anon, klass)).to eq false

      expect(KlassAccessPolicy.action_allowed?(:update, application, klass)).to eq false

      expect(KlassAccessPolicy.action_allowed?(:update, user, klass)).to eq false

      expect(KlassAccessPolicy.action_allowed?(:update, student.user, klass)).to eq false
    end

    it 'can be accessed by educators, course managers, school managers and administrators' do
      expect(KlassAccessPolicy.action_allowed?(
        :update, educator.user, klass)).to eq true

      expect(KlassAccessPolicy.action_allowed?(
        :update, course_manager.user, klass)).to eq true

      expect(KlassAccessPolicy.action_allowed?(
        :update, school_manager.user, klass)).to eq true

      expect(KlassAccessPolicy.action_allowed?(
        :update, administrator.user, klass)).to eq true
    end
  end
end
