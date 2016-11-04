require 'rails_helper'

RSpec.describe Tasks::GetPerformanceReportExports, type: :routine do
  it 'returns the export info related to courses' do
    course = FactoryGirl.create :course_profile_course

    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    user = User::User.new(strategy: strategy)

    role = AddUserAsCourseTeacher[course: course, user: user]

    physics_export = Tempfile.open(['Physics_I_Performance', '.xlsx']) do |physics_file|
      FactoryGirl.create(:tasks_performance_report_export,
                         export: physics_file,
                         course: course,
                         role: role)
    end

    biology_export = Tempfile.open(['Biology_I_Performance', '.xlsx']) do |biology_file|
      FactoryGirl.create(:tasks_performance_report_export,
                         export: biology_file,
                         course: course,
                         role: role)
    end

    export = described_class[course: course, role: role]

    # newest on top - enforced by default_scope in the model

    expect(export.length).to eq 2

    expect(export[0].filename).not_to include 'Biology_I_Performance'
    expect(export[0].filename).to include '.xlsx'
    expect(export[0].url).to eq biology_export.url
    expect(export[0].created_at).to be_the_same_time_as biology_export.created_at

    expect(export[1].filename).not_to include 'Physics_I_Performance'
    expect(export[1].filename).to include '.xlsx'
    expect(export[1].url).to eq physics_export.url
    expect(export[1].created_at).to be_the_same_time_as physics_export.created_at

    Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
      performance_report_export.try(:export).try(:file).try(:delete)
    end
  end
end
