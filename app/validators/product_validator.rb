# frozen_string_literal: true

require 'dry-schema'

class ProductValidator
  CreateSchema = Dry::Schema.Params do
    required(:name).filled(:string).value(max_size?: 255)
    optional(:description).maybe(:string).value(max_size?: 1000)
  end

  def self.validate_create(params)
    result = CreateSchema.call(params)
    
    if result.success?
      { success: true, data: result.to_h }
    else
      { success: false, errors: format_errors(result.errors.to_h) }
    end
  end

  def self.format_errors(errors_hash)
    errors_hash.transform_values do |messages|
      messages.map do |msg|
        case msg
        when String
          msg
        when Hash
          msg[:text] || msg['text'] || msg.to_s
        else
          msg.respond_to?(:text) ? msg.text : msg.to_s
        end
      end
    end
  end
end
