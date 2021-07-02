# frozen_string_literal: true

require "active_support/concern"

module InitiativeTypeFormExtend
  extend ActiveSupport::Concern

  included do

    attribute :cannot_accumulate_supports_beyond_threshold, Virtus::Attribute::Boolean
    attribute :comments_enabled, Virtus::Attribute::Boolean

  end
end

Decidim::Initiatives::Admin::InitiativeTypeForm.send(:include, InitiativeTypeFormExtend)
