module Categorizable
  extend ActiveSupport::Concern

  included do
    scope :food,       -> { where(category: "food") }
    scope :travel,     -> { where(category: "travel") }
    scope :medication, -> { where(category: "medication") }

    scope :recent, -> { order(created_at: :desc) }
    scope :oldest, -> { order(created_at: :asc) }

    scope :this_week,    -> { where(created_at: 1.week.ago..Time.current) }
    scope :last_14_days, -> { where(created_at: 14.days.ago..Time.current) }

    # quereies for the ai responses (which will have severity in its response) so that proper action could be taken for it
    scope :high_severity,   -> { where("ai_response->>'severity' = ?", "high") }
    scope :medium_severity, -> { where("ai_response->>'severity' = ?", "medium") }
    scope :low_severity,    -> { where("ai_response->>'severity' = ?", "low") }

    validates :prompt_input, presence: true
    validates :ai_response,  presence: true

    def severity
      ai_response["severity"].to_s
    end

    def summary
      ai_response["summary"].to_s.truncate(100)
    end

    def tips
      ai_response["tips"] || []
    end

    def estimated_savings
      ai_response["estimated_savings"].to_s
    end

    def category_score
      ai_response["category_score"].to_i
    end

    def budget_breakdown
      ai_response["budget_breakdown"] || []
    end

    def total_allocated
      ai_response["total_allocated"].to_i
    end

    def remaining
      ai_response["remaining"].to_i
    end

    def derive_action
      score = category_score
      sev   = severity

      if sev == "high" || score < 30
        :urgent_intervention
      elsif sev == "medium" || score < 50
        :review_spending
      elsif score < 70
        :set_budget_limit
      elsif sev == "low" && score < 85
        :seek_alternatives
      else
        :no_action
      end
    end
  end
end
