# frozen_string_literal: true

require "active_support/concern"

module AdminPermissionsExtend
  extend ActiveSupport::Concern

  included do
    def permissions
      # The public part needs to be implemented yet
      return permission_action if permission_action.scope != :admin
      return permission_action unless user

      user_can_enter_space_area?
      return permission_action if initiative && !initiative.is_a?(Decidim::Initiative)

      user_can_read_participatory_space?
      if !user.admin? && initiative&.has_authorship?(user)
        initiative_committee_action?
        initiative_user_action? if permission_action.action == :send_to_technical_validation # allow regular user to send initiative to tech validation
        attachment_action?
        return permission_action
      end

      disallow! and return permission_action unless user.admin? # disallow regular users to see initiatives on admin panel

      if !user.admin? && has_initiatives?
        read_initiative_list_action?
        return permission_action
      end
      return permission_action unless user.admin?

      initiative_type_action?
      initiative_type_scope_action?
      initiative_committee_action?
      initiative_admin_user_action?
      initiative_export_action?
      moderator_action?
      allow! if permission_action.subject == :attachment

      permission_action
    end

    private

    def attachment_action?
      return unless permission_action.subject == :attachment

      disallow! && return unless initiative.attachments_enabled?

      attachment = context.fetch(:attachment, nil)
      attached = attachment&.attached_to

      case permission_action.action
      when :update, :destroy
        toggle_allow(attached && attached.is_a?(Decidim::Initiative) && initiative.created?)
      when :create
        toggle_allow(initiative.created?)
      when :read
        allow!
      else
        disallow!
      end
    end

    def initiative_type_scope_action?
      return unless permission_action.subject == :initiative_type_scope

      initiative_type_scope = context.fetch(:initiative_type_scope, nil)
      initiative_type = initiative_type_scope&.type

      case permission_action.action
      when :destroy
        scopes_is_empty = initiative_type_scope && initiative_type_scope.initiatives.empty?
        is_global_scope = initiative_type_scope&.scope.nil?
        global_scope_required = initiative_type.only_global_scope_enabled? && initiative_type.scopes.present?
        toggle_allow(scopes_is_empty && !(is_global_scope && global_scope_required))
      else
        allow!
      end
    end

    def initiative_admin_user_action?
      return unless permission_action.subject == :initiative

      case permission_action.action
      when :read
        toggle_allow(Decidim::Initiatives.print_enabled)
      when :publish
        toggle_allow(initiative.validating?)
      when :unpublish
        toggle_allow(initiative.published?)
      when :discard
        toggle_allow(initiative.validating?)
      when :export_pdf_signatures
        toggle_allow(initiative.published? ||
                       initiative.accepted? ||
                       initiative.rejected? ||
                       initiative.examinated? ||
                       initiative.debatted? ||
                       initiative.classified?)
      when :export_votes
        toggle_allow(initiative.offline_signature_type? || initiative.any_signature_type?)
      when :accept
        allowed = initiative.published? &&
                  initiative.signature_end_date < Date.current &&
                  initiative.supports_goal_reached?
        toggle_allow(allowed)
      when :reject
        allowed = initiative.published? &&
                  initiative.signature_end_date < Date.current &&
                  initiative.supports_goal_reached?
        toggle_allow(allowed)
      when :send_to_technical_validation
        toggle_allow(allowed_to_send_to_technical_validation?)
      else
        allow!
      end
    end

    def initiative_export_action?
      allow! if permission_action.subject == :initiatives && permission_action.action == :export
    end
  end
end

Decidim::Initiatives::Admin::Permissions.send(:include, AdminPermissionsExtend)
