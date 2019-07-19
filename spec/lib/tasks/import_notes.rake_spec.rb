require 'rails_helper'

RSpec.describe 'import_notes', type: :rake do
  include_context 'rake'

  let(:page)       { FactoryBot.create :content_page }
  let(:user)       { FactoryBot.create :user }
  let(:course)     { FactoryBot.create :course_profile_course }
  let(:period)     { FactoryBot.create :course_membership_period, course: course }
  let(:role)       { AddUserAsPeriodStudent.call(user: user, period: period).outputs.role }

  let(:row) {
    [
      role.research_identifier,
      'fs-id1724224',
      page.cnx_id,
      '{ "one": 1 }',
      'hi this is note',
      '2018-02-06 17:10:48.099202',
      '2018-02-06 17:10:48.099202'
    ]
  }

  it 'creates a note' do
    expect(CSV).to receive(:foreach).with('file_path').and_yield(row)
    expect { call 'file_path','real' }.to change { Content::Models::Note.count }
  end
end
