module User
  class SetContentAnalystState
    lev_routine

    protected

    def exec(user:, content_analyst: false)
      return if (content_analyst && user.is_content_analyst?) || \
                (!content_analyst && !user.is_content_analyst?)

      content_analyst ? user.create_content_analyst! : user.content_analyst.destroy
    end
  end
end
