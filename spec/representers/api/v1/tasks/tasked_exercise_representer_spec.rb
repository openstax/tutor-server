require 'rails_helper'
require_relative 'tasked_exercise_representer_shared_examples'

RSpec.describe Api::V1::Tasks::TaskedExerciseRepresenter, type: :representer do
  include_examples 'a tasked_exercise representer'
end
