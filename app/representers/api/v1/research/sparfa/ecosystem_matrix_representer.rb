class Api::V1::Research::Sparfa::EcosystemMatrixRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :responded_before,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  collection :research_identifiers,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) do
               st = CourseMembership::Models::Student.arel_table
               research_identifier_by_uuid = Entity::Role.joins(:student).where(
                 student: { uuid: self.L_ids }
               ).pluck(st[:uuid], :research_identifier).to_h

               self.L_ids.map { |uuid| research_identifier_by_uuid[uuid] }
             end,
             schema_info: { required: true }

  collection :exercise_uids,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) do
               exercise_uid_by_uuid = {}
               Content::Models::Exercise.select(
                 :id, :number, :version, :uuid
               ).where(uuid: self.Q_ids).find_each do |exercise|
                 exercise_uid_by_uuid[exercise.uuid] = exercise.uid
               end

               self.Q_ids.map { |uuid| exercise_uid_by_uuid[uuid] }
             end,
             schema_info: { required: true }

  collection :L_ids,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :Q_ids,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :C_ids,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :d_data,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :W_data,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :W_row,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :W_col,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :H_mask_data,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :H_mask_row,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :H_mask_col,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :G_data,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :G_row,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :G_col,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :G_mask_data,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :G_mask_row,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :G_mask_col,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :U_data,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :U_row,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :U_col,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  property :superseded_at,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }
end
