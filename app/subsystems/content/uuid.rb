module Content
  class Uuid < String
    UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i

    def valid?
      match?(UUID_REGEX)
    end
  end
end
