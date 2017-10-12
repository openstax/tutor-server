module Content
  class DeleteEcosystem
    lev_routine

    protected

    def exec(id:)
      ecosystem = Content::Models::Ecosystem.find(id)
      fatal_error(
        code: :ecosystem_cannot_be_deleted,
        message: 'The ecosystem cannot be deleted because it is linked to a course',
      ) unless ecosystem.deletable?
      ecosystem.destroy!
      transfer_errors_from(ecosystem, { type: :verbatim }, true)
    end
  end
end
