require 'generate_token/token_generator'
require 'generate_token/secure_random_token_generator'
require 'generate_token/babbler_token_generator'

class GenerateToken
  def self.apply(record:, attribute:, mode: nil)
    @mode = mode || :hex

    begin
      record[attribute] = token_generator.generate_with(@mode)
    end while record.class.exists?(attribute => record[attribute])
  end

  private
  def self.token_generator
    TokenGenerator.selected_generator(@mode)
  end
end
