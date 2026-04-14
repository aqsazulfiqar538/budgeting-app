class AiBudgetService
	def initialize(category, prompt_input)
		@category     = category
		@prompt_input = prompt_input
	end

	def call
    chat     = RubyLLM.chat(model: "gemini-2.0-flash")
    response = chat.ask(full_prompt)
    JSON.parse(response.content)
  rescue JSON::ParserError
    default_response
  rescue StandardError => e
    default_response("Could not get AI response: #{e.message}")
  end

	private

	def full_prompt
    <<~PROMPT
      You are a personal budget advisor.
      The user wants advice about their #{@category} budget.

      Respond ONLY with a valid JSON object.
      No markdown. No explanation. No code fences. Raw JSON only.

      Use exactly this structure:
      {
        "summary": "one sentence overview of their situation",
        "tips": ["tip 1", "tip 2", "tip 3"],
        "estimated_savings": "e.g. Rs. 3,000/month or N/A",
        "severity": "low or medium or high",
        "category_score": a number from 0 to 100 representing budget health (100 = perfect)
      }

      User's question: #{@prompt_input}
    PROMPT
  end

	def default_response(message = "No response received.")
    {
      "summary"           => message,
      "tips"              => [],
      "estimated_savings" => "N/A",
      "severity"          => "low",
      "category_score"    => 0
    }
  end
end
