require "rails_helper"

RSpec.describe 'LMS Score Push', type: :request do

  let(:course) { FactoryGirl.create(:course_profile_course, is_lms_enabled: true) }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }
  let(:lms_app) { FactoryGirl.create(:lms_app, owner: course) }
  let(:user) { FactoryGirl.create(:user) }
  let(:simulator) { Lms::Simulator.new(self) }

  before(:each) {
    simulator.install_tutor(app: lms_app, course: "physics")
    simulator.set_launch_defaults(course: "physics", assignment: "tutor")
  }

  xit 'works' do
    # TODO get stubbed accounts to auto log in user
    simulator.add_student("bob")
    simulator.launch(user: "bob")

    simulator.expect_to_receive_score(student: "bob", assignment: "tutor", value: 0.9 )
  end

  it 'gracefully handles a student being dropped in the LMS course' do
  end

end
