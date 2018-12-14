module Api::V1::Tasks
  class TaskedExerciseRepresenter < TaskStepRepresenter

    property :url,
             as: :content_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The source URL for the Exercise containing the question being asked"
             },
             if: NOT_FEEDBACK_ONLY

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this Exercise"
             },
             if: NOT_FEEDBACK_ONLY

    property :is_in_multipart,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "If true, indicates this object is part of a multipart"
             },
             if: NOT_FEEDBACK_ONLY

    property :question_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The ID of the part, present even if there is only one part."
             },
             if: NOT_FEEDBACK_ONLY

    property :context,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's context (only present if required by the Exercise)"
             },
             if: NOT_FEEDBACK_ONLY

    property :content_hash_for_students,
             as: :content,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's content without attachments, vocab_term_uid, correctness, feedback or solutions"
             },
             if: NOT_FEEDBACK_ONLY

    # The properties below assume an Exercise with only 1 Question
    property :answer_id,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The answer id given by the student"
             },
             if: NOT_FEEDBACK_ONLY

    property :free_response,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The student's free response"
             },
             if: NOT_FEEDBACK_ONLY

    property :solution,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "A detailed solution that explains the correct choice"
             },
             if: FEEDBACK

    property :feedback,
             as: :feedback_html,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The feedback given to the student"
             },
             if: FEEDBACK

    property :correct_answer_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The Exercise's correct answer's id"
             },
             if: FEEDBACK

    property :is_correct?,
             as: :is_correct,
             writeable: false,
             readable: true,
             schema_info: {
               type: 'boolean',
               description: "Whether or not the answer given by the student is correct"
             },
             if: FEEDBACK

    def self.cache_key_for(represented, type)
      "#{represented.cache_key}/#{type}"
    end

    # Like Hash#deep_merge but also handles arrays
    def recursive_merge(enum1, enum2)
      return enum2 if enum1.nil?
      return enum1 if enum2.nil?

      case enum2
      when ::Hash
        enum1.dup.tap do |result_hash|
          enum2.each { |key, value| result_hash[key] = recursive_merge result_hash[key], value }
        end
      when ::Array
        max_index = [enum1.length, enum2.length].max
        max_index.times.map { |index| recursive_merge enum1[index], enum2[index] }
      else
        enum2
      end
    end

    def to_hash(options = {})
      user_options = options[:user_options] || {}

      no_feedback = Rails.cache.fetch(
        self.class.cache_key_for(represented, 'no_feedback'), expires_in: NEVER_EXPIRES
      ) do
         to_hash_without_cache(options.merge(user_options: user_options.merge(no_feedback: true)))
      end

      return no_feedback unless represented.task_step.feedback_available?

      feedback_only = Rails.cache.fetch(
        self.class.cache_key_for(represented, 'feedback_only'), expires_in: NEVER_EXPIRES
      ) do
        to_hash_without_cache(options.merge(user_options: user_options.merge(feedback_only: true)))
      end

      recursive_merge no_feedback, feedback_only
    end

  end
end
