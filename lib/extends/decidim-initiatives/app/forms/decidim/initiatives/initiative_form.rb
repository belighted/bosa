# frozen_string_literal: true
require "active_support/concern"

module InitiativeFormExtend
  extend ActiveSupport::Concern

  included do
    attribute :signature_end_date, Date
    attribute :attachment, AttachmentForm

    validate :notify_missing_attachment_if_errored
    validate :trigger_attachment_errors
    validates :signature_end_date, date: { after: Date.current }, if: lambda { |form|
      form.context.initiative_type.custom_signature_end_date_enabled? && form.signature_end_date.present?
    }

    def scope_id
      return nil if initiative_type.only_global_scope_enabled?

      super.presence
    end

    def initiative_type
      @initiative_type ||= ::Decidim::InitiativesType.find(type_id)
    end

    def available_scopes
      @available_scopes ||= if initiative_type.only_global_scope_enabled?
                              initiative_type.scopes.where(scope: nil)
                            else
                              initiative_type.scopes
                            end
    end

    def scope
      @scope ||= Scope.find(scope_id) if scope_id.present?
    end

    private

    def scope_exists
      return if scope_id.blank?

      errors.add(:scope_id, :invalid) unless InitiativesTypeScope.where(type: initiative_type, scope: scope).exists?
    end

    # This method will add an error to the `attachment` field only if there's
    # any error in any other field. This is needed because when the form has
    # an error, the attachment is lost, so we need a way to inform the user of
    # this problem.
    def notify_missing_attachment_if_errored
      return if attachment.blank?

      errors.add(:attachment, :needs_to_be_reattached) if errors.any?
    end

    def trigger_attachment_errors
      return if attachment.blank?
      return if attachment.valid?

      attachment.errors.each { |error| errors.add(:attachment, error) }

      attachment = Attachment.new(file: attachment.try(:file))

      errors.add(:attachment, :file) if !attachment.save && attachment.errors.has_key?(:file)
    end
  end
end

Decidim::Initiatives::InitiativeForm.send(:include, InitiativeFormExtend)
