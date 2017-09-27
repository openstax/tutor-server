require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Lms::SendCourseScores do

  let(:users) { 4.times.map { FactoryGirl.create(:user) } }
  let(:course) { FactoryGirl.create(:course_profile_course) }

  before(:each) { FactoryGirl.create(:lms_app, owner: course) }

  it 'works well for report_1' do
    sourcedids = %w(1 2 3 4)

    users.each_with_index do |user, ii|
      Lms::Models::CourseScoreCallback.find_or_create_by(
        result_sourcedid: sourcedids[ii],
        outcome_url: "http://simlms/outcome",
        course: course,
        profile: user.to_model
      )
    end

    allow(GetPerformanceReport).to receive(:[]).with(course: course) { report_1 }

    dummy_success_response = <<-EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <imsx_POXEnvelopeResponse xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
        <imsx_POXHeader>
          <imsx_POXResponseHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier>4560</imsx_messageIdentifier>
            <imsx_statusInfo>
              <imsx_codeMajor>success</imsx_codeMajor>
              <imsx_severity>status</imsx_severity>
              <imsx_description>Score for 3124567 is now 0.92</imsx_description>
              <imsx_messageRefIdentifier>999999123</imsx_messageRefIdentifier>
              <imsx_operationRefIdentifier>replaceResult</imsx_operationRefIdentifier>
            </imsx_statusInfo>
          </imsx_POXResponseHeaderInfo>
        </imsx_POXHeader>
        <imsx_POXBody>
          <replaceResultResponse/>
        </imsx_POXBody>
      </imsx_POXEnvelopeResponse>
    EOS

    stub_request(:post, /simlms/).to_return(status: 200, body: dummy_success_response, headers: {})

    described_class.perform_later(course: course)

    # TODO test that it actually did what it was supposed to do
  end

  def report_1
    [
      {
        period: {
          name: "1st"
        },
        students: [
          {
            name: users[0].name,
            student_identifier: "SID1",
            user: users[0].id,
            data: [],
            average_score: 2/3.0
          },
          {
            name: users[1].name,
            student_identifier: "SID89",
            user: users[1].id,
            is_dropped: true,
            data: [],
            average_score: 0.5,
          },
          {
            name: users[2].name,
            student_identifier: "SID2",
            user: users[2].id,
            data: [],
            # average_score not always included if no applicable tasks
          }
        ]
      },
      {
        period: {
          name: "2nd"
        },
        students: [
          {
            name: users[3].name,
            student_identifier: "SID42",
            user: users[3].id,
            data: [],
            average_score: 1.0
          },
        ]
      }
    ]
  end

  def report_with_empty_students
    [
      {
        period: {
          name: "1st"
        },
        data_headings: [],
        students: []
      }
    ]
  end

end
