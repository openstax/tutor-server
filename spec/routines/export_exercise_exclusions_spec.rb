require 'rails_helper'
require 'webmock/rspec'

RSpec.describe ExportExerciseExclusions, type: :routine do
  before(:each) do
    WebMock.disable_net_connect!
    stub_request(:put, /remote.php/).to_return(status: 200)
  end

  context "with data" do
    before(:all) do
      @course = FactoryGirl.create :course_profile_course
      @teacher_user = FactoryGirl.create :user, first_name: "Bob", last_name: "Martin"
      @teacher_role = AddUserAsCourseTeacher[course: @course, user: @teacher_user]

      @exercise = FactoryGirl.create :content_exercise

      @ee_1 = FactoryGirl.create :course_content_excluded_exercise,
                                 course: @course, exercise_number: @exercise.number
      @ee_2 = FactoryGirl.create :course_content_excluded_exercise, course: @course
      @ee_3 = FactoryGirl.create :course_content_excluded_exercise, course: @course
    end

    let(:outputs){ described_class.call.outputs }

    context "output by course" do
      let(:output){ outputs.by_course.first }

      it "includes the correct keys" do
        expect(output).to include(
          :course_id, :course_name, :teachers, :excluded_exercises_count,
          :excluded_exercises_numbers_with_urls, :page_uuids_with_urls
        )
      end

      context "returns a (Hashie Mash) hash with the correct data" do
        specify do
          expect(output).to be_a Hashie::Mash
        end

        specify "course id" do
          expect(output).to include(course_id: @ee_1.course.id)
        end

        specify "course name" do
          expect(output).to include(course_name: @ee_1.course.name)
        end

        specify "course teachers" do
          expect(output).to include(teachers: "Bob Martin")
        end

        specify "excluded exercises count" do
          expect(output).to include(excluded_exercises_count: 3)
        end

        context "excluded exercises numbers" do
          specify do
            ee_numbers = @course.excluded_exercises.map(&:exercise_number)
            expect(ee_numbers).to_not be_empty
            expect(output[:excluded_exercises_numbers_with_urls].map(&:ee_number)).to(
              match_array ee_numbers
            )
          end

          specify "with urls" do
            ee_numbers = @course.excluded_exercises.map(&:exercise_number)
            ee_numbers_urls = ee_numbers.map do |number|
              OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s
            end
            expect(output[:excluded_exercises_numbers_with_urls].map(&:ee_url)).to(
              match_array ee_numbers_urls
            )
          end
        end

        context "page uuids" do
          specify do
            expect(output[:page_uuids_with_urls].map(&:page_uuid)).to include(@exercise.page.uuid)
          end

          specify "with urls" do
            expect(output[:page_uuids_with_urls].map(&:page_url)).to(
              include(OpenStax::Cnx::V1.webview_url_for(@exercise.page.uuid))
            )
          end
        end
      end

      context "as csv" do
        it "includes all the correct data" do
          ee_numbers = @course.excluded_exercises.map(&:exercise_number)
          ee_numbers_urls = ee_numbers.map do |number|
            OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s
          end

          with_rows_from_csv("by_course") do |rows|
            headers = rows.first
            values = rows.second
            data = Hash[headers.zip(values)]

            expect(data["Course ID"]).to eq @ee_1.course.id.to_s
            expect(data["Course Name"]).to eq @ee_1.course.name
            expect(data["Teachers"]).to eq "Bob Martin"
            expect(data["# Exclusions"]).to eq "3"
            expect(data["Excluded Numbers"].split(", ")).to(
              match_array ee_numbers.map{|numb| "#{numb}"}
            )
            expect(data["Excluded Numbers URLs"].split(", ")).to match_array ee_numbers_urls
            expect(data["CNX Section UUID"]).to eq @exercise.page.uuid
            expect(data["CNX Section UUID URLs"]).to(
              eq OpenStax::Cnx::V1.webview_url_for(@exercise.page.uuid)
            )
          end
        end

        it 'uploads the exported data to owncloud' do
          file_regex_string = 'excluded_exercises_stats_by_course_\d+T\d+Z.csv'
          webdav_url_regex = Regexp.new "#{described_class::WEBDAV_BASE_URL}/#{file_regex_string}"

          # We simply test that the call to HTTParty is made properly
          expect(HTTParty).to receive(:put).with(
            webdav_url_regex,
            basic_auth: { username: a_kind_of(String).or(be_nil),
                          password: a_kind_of(String).or(be_nil) },
            body_stream: a_kind_of(File),
            headers: { 'Transfer-Encoding' => 'chunked' }
          ).and_return OpenStruct.new(success?: true)

          described_class.call(upload_by_course_to_owncloud: true)
        end
      end
    end

    context "output by exercise" do
      let!(:output){ outputs.by_exercise.first }

      it "includes the correct keys" do
        expect(output).to include(
          :exercise_number, :exercise_url, :excluded_exercises_count, :pages_with_uuids_and_urls
        )
      end

      context "returns a (Hashie Mash) hash with the correct" do
        specify do
          expect(output).to be_a Hashie::Mash
        end

        specify "exercise number" do
          expect(output[:exercise_number]).to eq @ee_1.exercise_number
        end

        specify "exercise url" do
          expected_uri = OpenStax::Exercises::V1.uri_for("/exercises/#{@ee_1.exercise_number}").to_s
          expect(output[:exercise_url]).to eq expected_uri
        end

        specify "exclusions count" do
          expect(output).to include(excluded_exercises_count: 1)
        end

        context "pages with uuids and urls" do
          it "includes the appropriate uuids" do
            expect(output[:pages_with_uuids_and_urls].map(&:page_uuid)).to(
              include(@exercise.page.uuid)
            )
          end

          specify "with urls" do
            expected_webview_url = OpenStax::Cnx::V1.webview_url_for(@exercise.page.uuid)
            expect(output[:pages_with_uuids_and_urls].map(&:page_url)).to(
              include(expected_webview_url)
            )
          end
        end
      end

      context "as csv" do
        it "includes all the correct data" do
          with_rows_from_csv("by_exercise") do |rows|
            headers = rows.first
            values = rows.second
            data = Hash[headers.zip(values)]

            expect(data["Exercise Number"]).to eq "#{@exercise.number}"
            expect(data["Exercise Number URL"]).to(
              eq OpenStax::Exercises::V1.uri_for("/exercises/#{@exercise.number}").to_s
            )
            expect(data["# Exclusions"]).to eq "1"
            expect(data["CNX Section UUID(s)"]).to eq @exercise.page.uuid
            expect(data["CNX Section UUID(s) URLs"]).to(
              eq OpenStax::Cnx::V1.webview_url_for(@exercise.page.uuid)
            )
          end
        end

        it 'uploads the exported data to owncloud' do
          file_regex_string = 'excluded_exercises_stats_by_exercise_\d+T\d+Z.csv'
          webdav_url_regex = Regexp.new "#{described_class::WEBDAV_BASE_URL}/#{file_regex_string}"

          # We simply test that the call to HTTParty is made properly
          expect(HTTParty).to receive(:put).with(
            webdav_url_regex,
            basic_auth: { username: a_kind_of(String).or(be_nil),
                          password: a_kind_of(String).or(be_nil) },
            body_stream: a_kind_of(File),
            headers: { 'Transfer-Encoding' => 'chunked' }
          ).and_return OpenStruct.new(success?: true)

          described_class.call(upload_by_exercise_to_owncloud: true)
        end
      end
    end
  end
  context "without data" do
    it "does not raise an exception" do
      expect{described_class.call}.to_not raise_error
    end
  end
end

def with_rows_from_csv(by_type, &block)
  expect_any_instance_of(described_class).to receive(:remove_exported_files) do |routine|
    filepath = routine.send "filepath_#{by_type}".to_sym
    expect(File.exist?(filepath)).to be true
    expect(filepath.ends_with? '.csv').to be true
    rows = CSV.read(filepath)
    block.call(rows)
  end

  by_course = by_type == "by_course"
  by_exercise = by_type == "by_exercise"
  described_class.call(
    upload_by_course_to_owncloud: by_course, upload_by_exercise_to_owncloud: by_exercise
  )
end
