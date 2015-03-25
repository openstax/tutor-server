require 'rails_helper'
# require 'vcr_helper'
require 'tasks/sprint/sprint_008/pw_real'

RSpec.describe Sprint008::PwReal, type: :request, 
                                  version: :v1,
                                  speed: :slow do 
                                  # vcr: VCR_OPTS 

  it "doesn't catch on fire" do
    result = Sprint008::PwReal.call

    expect(result.outputs.task).to be_an_instance_of(Task)
    expect(result.outputs.task.task_steps.first.tasked).to be_an_instance_of(TaskedExercise)
  end

end
