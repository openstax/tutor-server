class Task < ActiveRecord::Base
  belongs_to :taskable, polymorphic: true
  belongs_to :details, polymorphic: true
end
