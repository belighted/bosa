# frozen_string_literal: true

require "active_support/concern"

module PermissionsExtend
  extend ActiveSupport::Concern

  # Changes moved from decidim-module-initiatives_nosignature_allowed

  included do
    def permissions
      # Delegate the admin permission checks to the admin permissions class
      return Decidim::Initiatives::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
      return permission_action if permission_action.scope != :public

      # Non-logged users permissions
      public_report_content_action?
      list_public_initiatives?
      read_public_initiative?
      search_initiative_types_and_scopes?
      request_membership?

      return permission_action unless user

      create_initiative?
      edit_public_initiative?
      update_public_initiative?

      create_initiative_with_type?

      vote_initiative?
      sign_initiative?
      unvote_initiative?

      initiative_attachment?

      initiative_committee_action?
      send_to_technical_validation?

      permission_action
    end

    private

    def initiative_type
      @initiative_type ||= context.fetch(:initiative_type, nil) || initiative.type
    end

    def read_public_initiative?
      return unless [:initiative, :participatory_space].include?(permission_action.subject) &&
        permission_action.action == :read

      return allow! if readable?(initiative)
      return allow! if user && authorship_or_admin?

      disallow!
    end

    def creation_enabled?
      Decidim::Initiatives.creation_enabled &&
        organization_initiatives_settings_allow_to_create? &&
        (creation_authorized? || Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?)
    end

    def create_initiative_with_type?
      return unless permission_action.subject == :initiative_type &&
                    permission_action.action == :create

      toggle_allow(creation_enabled_for?(initiative_type))
    end

    def creation_enabled_for?(initiative_type)
      Decidim::Initiatives.creation_enabled && (
      creation_authorized_for?(initiative_type) || Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
    )
    end

    # def request_membership?
    #   return unless permission_action.subject == :initiative &&
    #                 permission_action.action == :request_membership
    #
    #   can_request = !initiative.published? &&
    #                 initiative.promoting_committee_enabled? &&
    #                 !initiative.has_authorship?(user) &&
    #                 (
    #                 Decidim::Initiatives.do_not_require_authorization ||
    #                   Decidim::Initiatives::UserAuthorizations.for(user).any? ||
    #                   Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
    #               )
    #
    #   toggle_allow(can_request)
    # end
    #
    # def access_request_membership?
    #   !initiative.published? &&
    #     initiative.promoting_committee_enabled? &&
    #     !initiative.has_authorship?(user) &&
    #     (
    #     Decidim::Initiatives.do_not_require_authorization ||
    #       Decidim::ActionAuthorizer.new(user, :create, initiative_type, initiative_type).authorize.ok? ||
    #       Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?
    #     )
    # end

    def creation_authorized?
      return true if Decidim::Initiatives.do_not_require_authorization
      return true if available_verification_workflows.empty?

      Decidim::Initiatives::InitiativeTypes.for(user.organization).find do |type|
        Decidim::ActionAuthorizer.new(user, :create, type, type).authorize.ok?
      end.present?
    end

    def creation_authorized_for?(initiative_type)
      return true if Decidim::Initiatives.do_not_require_authorization
      return true if available_verification_workflows.empty?

      Decidim::ActionAuthorizer.new(user, :create, initiative_type, initiative_type).authorize.ok?
    end

    def unvote_initiative?
      return unless permission_action.action == :unvote &&
        permission_action.subject == :initiative

      can_unvote = initiative.accepts_online_unvotes? &&
        initiative.organization&.id == user.organization&.id &&
        organization_initiatives_settings_allow_to_vote? &&
        initiative.votes.where(author: user).any? &&
        # (can_user_support?(initiative) || Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?) &&
        authorized?(:vote, resource: initiative, permissions_holder: initiative.type)

      toggle_allow(can_unvote)
    end

    def can_vote?
      return if initiative.no_signature?

      initiative.votes_enabled? &&
        initiative.organization&.id == user.organization&.id &&
        initiative.accepts_votes_beyond_threshold? &&
        organization_initiatives_settings_allow_to_vote? &&
        initiative.votes.where(author: user).empty? &&
        # (can_user_support?(initiative) || Decidim::UserGroups::ManageableUserGroups.for(user).verified.any?) &&
        authorized?(:vote, resource: initiative, permissions_holder: initiative.type)
    end

    def organization_initiatives_settings_allow_to_create?
      organization_initiatives_settings_allow_to?('create')
    end

    def organization_initiatives_settings_allow_to_vote?
      organization_initiatives_settings_allow_to?('sign')
    end

    def organization_initiatives_settings_allow_to?(action)
      organization = initiative&.organization || user&.organization
      organization.initiatives_settings_allow_to?(user, action)
    end

    def readable?(initiative)
      return false if initiative.blank?

      initiative.published? || initiative.rejected? || initiative.accepted? ||
        initiative.debatted? || initiative.examinated? || initiative.classified?
    end

  end
end

Decidim::Initiatives::Permissions.send(:include, PermissionsExtend)
