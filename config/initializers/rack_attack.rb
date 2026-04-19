# frozen_string_literal: true

class Rack::Attack
  # Throttle login attempts by IP
  throttle("login/ip", limit: 5, period: 60.seconds) do |req|
    req.ip if req.path == "/api/v1/login" && req.post?
  end

  # Throttle signup by IP
  throttle("signup/ip", limit: 3, period: 60.seconds) do |req|
    req.ip if req.path == "/api/v1/signup" && req.post?
  end

  # Throttle password reset by IP
  throttle("password_reset/ip", limit: 3, period: 60.seconds) do |req|
    req.ip if req.path == "/api/v1/password" && req.post?
  end

  # General API throttle per IP
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # rack-attack 6.x uses a hash argument for throttled_responder
  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => retry_after.to_s
    }
    body = { errors: [ "Rate limit exceeded. Please try again later." ] }.to_json
    [ 429, headers, [ body ] ]
  end
end
