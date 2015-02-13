class KlassAssistant < ActiveRecord::Base
  belongs_to :klass
  belongs_to :assistant

  serialize :settings
  serialize :data

  validates :klass, presence: true
  validates :assistant, presence: true, uniqueness: { scope: :klass_id }
end
