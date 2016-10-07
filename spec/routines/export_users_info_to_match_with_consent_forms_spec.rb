require 'rails_helper'

RSpec.describe ExportUsersInfoToMatchWithConsentForms, type: :routine do

  context "as a Lev output with student information" do
    let!(:course){ FactoryGirl.create :entity_course }
    let!(:user_1){ FactoryGirl.create :user, username: "TonyStark", first_name: "Tony", last_name: "Stark" }
    let!(:some_other_user){ FactoryGirl.create :user }
    let!(:period){ FactoryGirl.create :course_membership_period, course: course }

    before(:each) do
      role_1 = AddUserAsPeriodStudent[period: period, user: user_1, student_identifier: "333999"]
      @student_1 = role_1.student
    end

    let!(:outputs){ described_class.call.outputs }
    let!(:first_output){ outputs.info[0] }

    it "includes the user id from Accounts" do
      expect(first_output.user_id).to eq user_1.to_model.account.openstax_uid
    end

    it 'includes student\'s school id ("student identifier")' do
      expect(first_output.student_identifiers).to match_array course.students.map(&:student_identifier)
    end

    it "includes name" do
      expect(first_output.name).to eq "Tony Stark"
    end

    it "includes username" do
      expect(first_output.username).to eq "TonyStark"
    end

    context "as csv file with student information" do
      it "includes all the information it should" do
        with_csv_rows_to_match_w_consent_forms do |rows|
          headers = rows.first
          values = rows.second
          data = Hash[headers.zip(values)]

          expect(rows.count).to eq 3
          expect(data["User ID"]).to eq user_1.to_model.account.openstax_uid.to_s
          expect(data["Student Identifiers"]).to eq "333999"
          expect(data["Name"]).to eq "Tony Stark"
          expect(data["Username"]).to eq "TonyStark"
        end
      end
    end
  end

end

def with_csv_rows_to_match_w_consent_forms(&block)
  expect_any_instance_of(described_class).to receive(:remove_exported_files) do |routine|
    filepath = routine.send :filename
    expect(File.exists?(filepath)).to be true
    expect(filepath.ends_with? '.csv').to be true
    rows = CSV.read(filepath)
    block.call(rows)
  end

  described_class.call
end
