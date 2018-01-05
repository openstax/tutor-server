class Api::V1::ResearchSurveyRepresenter < Roar::Decorator

  include Roar::JSON

  property :id,
           type: String,
           readable: true,
           writeable: false

  property :title,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { survey_plan.title_for_students }

  property :model,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { survey_plan.survey_js_model }

  property :response,
           type: String,
           readable: false,
           writeable: true

end
