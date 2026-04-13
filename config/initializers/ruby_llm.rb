RubyLLM.configure do |config|
  config.gemini_api_key = Rails.application.credentials.dig(:gemini, :api_key)
end
