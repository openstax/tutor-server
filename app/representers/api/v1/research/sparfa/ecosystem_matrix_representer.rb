class Api::V1::Research::Sparfa::EcosystemMatrixRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :responded_before,
           type: DateTime,
           readable: true,
           writeable: false

  collection :research_identifiers,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :exercise_numbers,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :page_uuids,
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
           type: DateTime,
           readable: true,
           writeable: false
end
