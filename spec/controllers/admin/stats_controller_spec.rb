require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Admin::StatsController, type: :controller do
  context "with an admin signed in" do
    let(:admin)   { FactoryGirl.create(:user, :administrator) }

    before(:each) { controller.sign_in admin }

    context "GET #courses" do
      let(:course)         { FactoryGirl.create :course_profile_course }
      let(:periods)        do
        3.times.map { FactoryGirl.create :course_membership_period, course: course }
      end

      let(:teacher_user)        { FactoryGirl.create :user }
      let!(:teacher_role)       { AddUserAsCourseTeacher[course: course, user: teacher_user] }

      let!(:student_roles) do
        5.times.map do
          user = FactoryGirl.create :user
          AddUserAsPeriodStudent[period: periods.sample, user: user]
        end
      end

      it "returns http success" do
        get :courses
        expect(response).to have_http_status(:success)
      end
    end

    context "GET #excluded_exercises" do
      context "with excluded exercises in the database" do
        let(:course)         { FactoryGirl.create :course_profile_course }

        let(:teacher_user)   { FactoryGirl.create :user }
        let!(:teacher_role)  { AddUserAsCourseTeacher[course: course, user: teacher_user] }

        let!(:excluded_exercises) do
          5.times.map { FactoryGirl.create :course_content_excluded_exercise, course: course }
        end

        it "returns http success" do
          get :excluded_exercises
          expect(response).to have_http_status(:success)
        end

        it "assigns @excluded_exercises_by_course" do
          get :excluded_exercises
          expect(assigns[:excluded_exercises_by_course]).to be_an(Array)
        end

        it "assigns @excluded_exercises_by_exercise" do
          get :excluded_exercises
          expect(assigns[:excluded_exercises_by_exercise]).to be_an(Array)
        end
      end

      context "with 0 excluded exercises in the database" do
        before(:each) do
          expect(CourseContent::Models::ExcludedExercise.count).to eq 0
        end

        it "assigns @excluded_exercises_by_course as an empty array" do
          get :excluded_exercises
          expect(assigns[:excluded_exercises_by_course]).to be_an(Array)
          expect(assigns[:excluded_exercises_by_course]).to be_empty
        end

        it "assigns @excluded_exercises_by_exercise as an empty array" do
          get :excluded_exercises
          expect(assigns[:excluded_exercises_by_exercise]).to be_an(Array)
          expect(assigns[:excluded_exercises_by_exercise]).to be_empty
        end

        it "doesn't raise error" do
          expect{get :excluded_exercises}.to_not raise_error
        end
      end
    end

    context "POST #excluded_exercises_to_csv" do
      let(:course)              { FactoryGirl.create :course_profile_course }
      let!(:excluded_exercises) do
        5.times.map { FactoryGirl.create :course_content_excluded_exercise, course: course }
      end

      context "with by_course and by_exercise params" do
        before do
          expect(ExportExerciseExclusions).to(
            receive(:perform_later).with(
              upload_by_course_to_owncloud: true, upload_by_exercise_to_owncloud: true
            ).and_return(true)
          )
        end

        it "does a redirect" do
          post :excluded_exercises_to_csv, export: { by: ["course", "exercise"] }
          expect(response).to redirect_to excluded_exercises_admin_stats_path
        end

        it "renders a flash success" do
          post :excluded_exercises_to_csv, export: { by: ["course", "exercise"] }
          expect(flash[:success]).to be_present
        end
      end

      context "without by_course or by_exercise params" do
        it "does a redirect" do
          post :excluded_exercises_to_csv, export: { by: [""] }
          expect(response).to redirect_to excluded_exercises_admin_stats_path
        end

        it "renders a flash alert" do
          post :excluded_exercises_to_csv, export: { by: [""] }
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "GET #concept_coach" do
      let(:tasks)     { 3.times.map { FactoryGirl.create :tasks_task, task_type: :concept_coach } }
      let!(:cc_tasks) do
        tasks.map{ |task| FactoryGirl.create :tasks_concept_coach_task, task: task }
      end

      it "returns http success" do
        get :concept_coach
        expect(response).to have_http_status(:success)
      end
    end
  end
end
