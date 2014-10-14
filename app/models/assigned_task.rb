class AssignedTask < ActiveRecord::Base
  belongs_to :assignee, polymorphic: true
  belongs_to :task, counter_cache: true
  belongs_to :user

  # One might consider writing a validation to ensure that the user to which
  # this AssignedTask belongs matches the user under the assignee.  However,
  # there would only ever be a disagreement if the AssignTask routine set these
  # values improperly (there is no other setting of these values).  So, instead
  # of testing something which is unlikely to happen over and over at runtime,
  # let's just verify that the AssignTask routine does what it should.
end
