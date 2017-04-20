require 'rails_helper'
require_relative 'shared_examples_for_create_practice_task_routines'

RSpec.describe CreatePracticeSpecificTopicsTask, type: :routine do

  include_examples 'a routine that creates practice tasks',
                   -> { described_class.call course: course, role: role, page_ids: [ page.id ] }

  it 'errors when there are not enough local exercises for the widget' do
    expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return([])
    expect(result.errors.first.code).to eq :no_exercises
  end

end
