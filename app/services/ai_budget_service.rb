class AiBudgetService
  def initialize(category, prompt_input)
    @category     = category
    @prompt_input = prompt_input
  end

  def call
    chat     = RubyLLM.chat(model: "gemini-2.5-flash-lite")
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
      You are a personal budget advisor helping a user plan their #{@category} budget.

      Your job is to create a concrete, actionable budget plan based on what the user tells you.
      Break down their budget into specific spending categories with exact amounts in Pakistani Rupees (Rs.).

      Respond ONLY with a valid JSON object. No markdown. No explanation. No code fences. Raw JSON only.
      Use exactly this structure:
      {
        "summary": "one sentence overview of their budget plan",
        "budget_breakdown": [
          { "label": "category name", "amount": 3000, "note": "brief advice for this line item" }
        ],
        "total_allocated": total of all amounts as a number,
        "remaining": unallocated amount as a number (can be 0 or negative),
        "tips": ["specific actionable tip 1", "specific actionable tip 2"],
        "estimated_savings": "e.g. Rs. 3,000/month or N/A",
        "severity": "low or medium or high",
        "category_score": a number from 0 to 100 representing budget health (100 = perfect)
      }

      User's request: #{@prompt_input}
    PROMPT
  end

  def default_response(message = "No response received.")
    {
      "summary"          => message,
      "budget_breakdown" => [],
      "total_allocated"  => 0,
      "remaining"        => 0,
      "tips"             => [],
      "estimated_savings"=> "N/A",
      "severity"         => "low",
      "category_score"   => 0
    }
  end
end