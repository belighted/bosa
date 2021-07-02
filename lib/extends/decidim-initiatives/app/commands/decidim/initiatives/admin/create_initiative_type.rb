# frozen_string_literal: true

require "active_support/concern"

module CreateInitiativeTypeExtend
  extend ActiveSupport::Concern

  included do
    private

    def create_initiative_type
      initiative_type = InitiativesType.new(
        organization: form.current_organization,
        title: form.title,
        description: form.description,
        signature_type: form.signature_type,
        attachments_enabled: form.attachments_enabled,
        undo_online_signatures_enabled: form.undo_online_signatures_enabled,
        cannot_accumulate_supports_beyond_threshold: form.cannot_accumulate_supports_beyond_threshold,
        custom_signature_end_date_enabled: form.custom_signature_end_date_enabled,
        area_enabled: form.area_enabled,
        promoting_committee_enabled: form.promoting_committee_enabled,
        comments_enabled: form.comments_enabled,
        minimum_committee_members: form.minimum_committee_members,
        banner_image: form.banner_image,
        collect_user_extra_fields: form.collect_user_extra_fields,
        extra_fields_legal_information: form.extra_fields_legal_information,
        validate_sms_code_on_votes: form.validate_sms_code_on_votes,
        document_number_authorization_handler: form.document_number_authorization_handler,
        child_scope_threshold_enabled: form.child_scope_threshold_enabled,
        only_global_scope_enabled: form.only_global_scope_enabled,
        no_signature_allowed: form.no_signature_allowed
      )

      return initiative_type unless initiative_type.valid?

      initiative_type.save
      initiative_type
    end
  end
end

Decidim::Initiatives::Admin::CreateInitiativeType.send(:include, CreateInitiativeTypeExtend)
