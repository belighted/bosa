# frozen_string_literal: true

if Rails.env.production?
  require "rack/attack"

  Rack::Attack.enabled = false
end
