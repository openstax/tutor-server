require 'rails_helper'

RSpec.describe Lms::SendCourseScores do

  it 'does not have blank space before the XML declaration' do
    # such blank space is not allowed and some LMSes flip out
    expect(Lms::SendCourseScores.new.basic_outcome_xml(score: 0.5, sourcedid: 'hi')[0]).not_to match(/\s/)
  end

end
