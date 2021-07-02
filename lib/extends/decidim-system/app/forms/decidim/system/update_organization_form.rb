# frozen_string_literal: true

require "active_support/concern"

module UpdateOrganizationFormExtend
  extend ActiveSupport::Concern

  included do
    attribute :castings_enabled, Virtus::Attribute::Boolean
    attribute :basic_auth_username, String
    attribute :basic_auth_password, String
    jsonb_attribute :initiatives_settings, [
      [:allow_users_to_see_initiative_no_signature_option, Virtus::Attribute::Boolean],
      [:allow_users_to_see_initiative_attachments, Virtus::Attribute::Boolean],
      [:hide_areas_filter, Virtus::Attribute::Boolean],
      [:hide_scopes_filter, Virtus::Attribute::Boolean],
      [:create_initiative_minimum_age, Integer],
      [:create_initiative_allowed_regions, String],
      [:sign_initiative_minimum_age, Integer],
      [:sign_initiative_allowed_regions, String]
    ]

  end
end

Decidim::System::UpdateOrganizationForm.send(:include, UpdateOrganizationFormExtend)
