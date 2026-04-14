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
  end
end
