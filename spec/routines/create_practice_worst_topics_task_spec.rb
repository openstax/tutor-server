require 'rails_helper'
require_relative 'shared_examples_for_create_practice_task_routines'

RSpec.describe CreatePracticeWorstTopicsTask, type: :routine do

  include_examples 'a routine that creates practice tasks',
                   -> { described_class.call course: course, role: role },
                   :fetch_practice_worst_areas_exercises,
                   false

end
