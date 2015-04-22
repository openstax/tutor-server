require 'rails_helper'

RSpec.describe Content::GetExercise, :type => :routine do

  let!(:exercise_1) { FactoryGirl.create(:content_exercise,
                                         content: '{"uid": "1@1"}') }
  let!(:exercise_2) { FactoryGirl.create(:content_exercise,
                                         content: '{"uid": "2@1"}') }

  it "should get the Exercise by id and return a wrapper around it" do
    exercise = Content::GetExercise[id: exercise_1.id]
    expect(exercise).to be_a(Exercise)
    expect(exercise.content).to eq exercise_1.content

    exercise = Content::GetExercise[id: exercise_2.id]
    expect(exercise).to be_a(Exercise)
    expect(exercise.content).to eq exercise_2.content
  end

end
