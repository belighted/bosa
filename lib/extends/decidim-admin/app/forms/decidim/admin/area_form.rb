# frozen_string_literal: true

require "active_support/concern"

module AreaFormExtend
  extend ActiveSupport::Concern

  included do
    attribute :color
    attribute :logo
    attribute :remove_logo

    validates :logo, passthru: { to: Decidim::Area }
    validates :color, format: { with: /#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}/i }
  end
end

Decidim::Admin::AreaForm.send(:include, AreaFormExtend)
