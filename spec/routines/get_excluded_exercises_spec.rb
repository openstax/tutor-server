require 'rails_helper'

describe GetExcludedExercises, type: :routine do
  context "with data" do
    let!(:course){ FactoryGirl.create :entity_course }
    let(:teacher_user)   { FactoryGirl.create :user, first_name: "Bob", last_name: "Martin" }
    let!(:teacher_role)  { AddUserAsCourseTeacher[course: course, user: teacher_user] }

    let!(:exercise) { FactoryGirl.create :content_exercise }

    let!(:ee_1){ FactoryGirl.create :course_content_excluded_exercise, course: course, exercise_number: exercise.number }
    let!(:ee_2){ FactoryGirl.create :course_content_excluded_exercise, course: course }
    let!(:ee_3){ FactoryGirl.create :course_content_excluded_exercise, course: course }
    let!(:outputs){ described_class.call.outputs }

    context "output by course" do
      let!(:output){ outputs.by_course.first }

      it "includes the correct keys" do
        expect(output).to include(:course_id, :course_name, :teachers, :ee_count, :ee_numbers_with_urls, :page_uuids_with_urls)
      end

      context "returns a (Hashie Mash) hash with the correct" do
        specify do
          expect(output).to be_a Hashie::Mash
        end

        specify "course id" do
          expect(output).to include(course_id: ee_1.course.id)
        end

        specify "course name" do
          expect(output).to include(course_name: ee_1.course.name)
        end

        specify "course teachers" do
          expect(output).to include(teachers: ee_1.course.teachers.map(&:name).join(", "))
        end

        specify "excluded exercises count (length)" do
          expect(output).to include(ee_count: 3)
        end

        context "excluded exercises numbers" do
          specify do
            ee_numbers = course.excluded_exercises.map(&:exercise_number)
            expect(ee_numbers).to_not be_empty
            expect(output[:ee_numbers_with_urls].map(&:ee_number)).to match_array ee_numbers
          end

          specify "with urls" do
            ee_numbers = course.excluded_exercises.map(&:exercise_number)
            ee_numbers_urls = ee_numbers.map{|number| OpenStax::Exercises::V1.uri_for("/exercises/#{number}").to_s }
            expect(output[:ee_numbers_with_urls].map(&:ee_url)).to match_array ee_numbers_urls
          end
        end

        context "page uuids" do
          specify do
            expect(output[:page_uuids_with_urls].map(&:page_uuid)).to include(exercise.page.uuid)
          end

          specify "with urls" do
            expect(output[:page_uuids_with_urls].map(&:page_url)).to include(OpenStax::Cnx::V1.webview_url_for(exercise.page.uuid))
          end
        end
      end
    end

    context "output by exercise" do
      let!(:output){ outputs.by_exercise.first }

      it "includes the correct keys" do
        expect(output).to include(:ee_number, :ee_url, :ee_count, :pages_with_uuids_and_urls)
      end

      context "returns a (Hashie Mash) hash with the correct" do
        specify "exercise number" do
          expect(output[:ee_number]).to eq ee_1.exercise_number
        end

        specify "exercise url" do
          expected_uri = OpenStax::Exercises::V1.uri_for("/exercises/#{ee_1.exercise_number}").to_s
          expect(output[:ee_url]).to eq expected_uri
        end

        specify "exclusions count" do
          expect(output).to include(ee_count: 1)
        end

        context "pages with uuids and urls" do
          it "includes the appropriate uuids" do
            expect(output[:pages_with_uuids_and_urls].map(&:page_uuid)).to include(exercise.page.uuid)
          end

          specify "with urls" do
            expected_webview_url = OpenStax::Cnx::V1.webview_url_for(exercise.page.uuid)
            expect(output[:pages_with_uuids_and_urls].map(&:page_url)).to include(expected_webview_url)
          end
        end
      end
    end
  end
  context "without data" do
    it "does not raise an exception" do
      expect{described_class.call}.to_not raise_exception(StandardError)
    end
  end
end
