# frozen_string_literal: true

require "active_support/concern"

module InitiativeFormExtend
  extend ActiveSupport::Concern

  included do

    clear_validators!
    validates :title, :description, presence: true
    validates :signature_type, presence: true
    validates :type_id, presence: true
    validates :area, presence: true, if: ->(form) { form.area_id.present? }
    validate :scope_exists
    validate :notify_missing_attachment_if_errored
    validate :trigger_attachment_errors
    validates :signature_end_date, date: { after: Date.current }, if: lambda { |form|
      form.context.initiative_type.custom_signature_end_date_enabled? && form.signature_end_date.present?
    }

    validates :description, length: {maximum: 4000}

    def scope_id
      return nil if initiative_type.only_global_scope_enabled?

      super.presence
    end

    def initiative_type
      @initiative_type ||= Decidim::InitiativesType.find(type_id)
    end

    def available_scopes
      @available_scopes ||= if initiative_type.only_global_scope_enabled?
                              initiative_type.scopes.where(scope: nil)
                            else
                              initiative_type.scopes
                            end
    end

    def scope
      @scope ||= Decidim::Scope.find(scope_id) if scope_id.present?
    end

    private

    # def scope_exists
    #   return if scope_id.blank?
    #
    #   errors.add(:scope_id, :invalid) unless InitiativesTypeScope.where(type: initiative_type, scope: scope).exists?
    # end

    # def type
    #   @type ||= Decidim::InitiativesType.find(type_id)
    # end

    def notify_missing_attachment_if_errored
      return if attachment.blank? || attachment.file.blank?

      errors.add(:attachment, :needs_to_be_reattached) if errors.any?
    end

    def trigger_attachment_errors
      return if attachment.blank? || attachment.file.blank?
      return if attachment.valid?

      if attachment.errors.has_key?(:title)
        errors.add(:attachment, :title)
        errors.add(:attachment, :needs_to_be_reattached)
      elsif errors.keys.reject {|k| k == :attachment}.blank?
        attachment.errors.each {|error| errors.add(:attachment, error)}
        attachment = Attachment.new(file: attachment.try(:file))
        errors.add(:attachment, :file) if !attachment.save && attachment.errors.has_key?(:file)
      end
    end
  end
end

Decidim::Initiatives::InitiativeForm.send(:include, InitiativeFormExtend)
