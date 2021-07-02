# frozen_string_literal: true

require "active_support/concern"

module VoteFormExtend
  extend ActiveSupport::Concern

  included do
    attribute :user_scope_id, Integer
    attribute :resident, Virtus::Attribute::Boolean

    # attribute :initiative, Integer
    # attribute :signer, Integer

    clear_validators!
    validates :initiative, :signer, presence: true

    validates :authorized_scopes, presence: true

    with_options if: :required_personal_data? do
      validates :encrypted_metadata, :hash_id, :resident, presence: true
      validate :already_voted?
      validate :user_scope_belongs_to_organization?
      validates :resident, acceptance: true
    end

    def metadata
      {
        user_scope_id: user_scope_id,
        resident: resident
      }
    end

    # def encrypted_metadata
    #   return unless required_personal_data?
    #
    #   @encrypted_metadata ||= encryptor.encrypt({})
    # end

    # Public: Builds the list of scopes where the user is authorized to vote in. This is used when
    # the initiative allows also voting on child scopes, not only the main scope.
    #
    # Instead of just listing the children of the main scope, we just want to select the ones that
    # have been added to the InitiativeType with its voting settings.
    #
    # def authorized_scopes
    #   initiative.votable_initiative_type_scopes.select do |initiative_type_scope|
    #     initiative_type_scope.global_scope? ||
    #       initiative_type_scope.scope == user_authorized_scope ||
    #       initiative_type_scope.scope.ancestor_of?(user_authorized_scope)
    #   end.flat_map(&:scope)
    # end
    #
    # Revert back from v0.24 (above) to custom code (below):
    #   it skips the global scope from the list when allows voting on child scopes
    #   + in `_progress_bar.html.erb` show the amount via `online_votes_count` instead of `online_votes_count_for`
    #
    def authorized_scopes
      list = initiative.votable_initiative_type_scopes.select do |initiative_type_scope|
        if initiative_type_scope.scope.present?
          initiative_type_scope.scope == user_authorized_scope ||
            initiative_type_scope.scope.ancestor_of?(user_authorized_scope)
        else
          initiative.type.only_global_scope_enabled && user_authorized_scope.nil?
        end
      end
      list.flat_map(&:scope)
    end

    # Public: Finds the scope the user has an authorization for, this way the user can vote
    # on that scope and its parents.
    #
    # This is can be used to allow users that are authorized with a children
    # scope to sign an initiative with a parent scope.
    #
    # As an example: A city (global scope) has many districts (scopes with
    # parent nil), and each district has different neighbourhoods (with its
    # parent as a district). If we setup the authorization handler to match
    # a neighbourhood, the same authorization can be used to participate
    # in district, neighbourhoods or city initiatives.
    #
    # Returns a Decidim::Scope.
    def user_authorized_scope
      return scope if handler_name.blank?
      return unless authorized?

      manifest = Decidim::Verifications.workflows.find { |m| m.name == handler_name }
      return unless manifest

      @user_authorized_scope ||= authorized_scope_candidates.find do |candidates|
        return false unless candidates

        authorization.metadata.symbolize_keys.dig(:scope_id) == candidates&.id
      end
    end

    # Public: Builds a list of Decidim::Scopes where the user could have a
    # valid authorization.
    #
    # If the intiative is set with a global scope (meaning the scope is nil),
    # all the scopes in the organizaton are valid.
    #
    # Returns an array of Decidim::Scopes.
    def authorized_scope_candidates
      return initiative.organization.scopes if scope.blank?

      initiative.scope.descendants
    end

    protected

    # Private: Checks if the data given at the vote form matches the same data
    # we have at the authorization.
    def personal_data_consistent_with_metadata
      return if initiative.document_number_authorization_handler.blank?

      errors.add(:base, :invalid) unless authorized? && authorization_handler && user_authorized_scope
    end

    # Private: Builds an authorization handler with the data the user provided
    # when signing the initiative.
    #
    # This is currently tied to authorization handlers that have, at least, these attributes:
    #   * document_number
    #   * name_and_surname
    #   * date_of_birth
    #   * postal_code
    #
    # Once we have the authorization handler we can use is to compute the
    # unique_id and compare it to an existing authorization.
    #
    # Returns a Decidim::AuthorizationHandler.
    def authorization_handler
      return unless document_number && handler_name

      @authorization_handler ||= Decidim::AuthorizationHandler.handler_for(handler_name)
    end

    def authorization_status
      return unless authorization

      Decidim::Verifications::Adapter.from_element(handler_name).authorize(authorization, {}, nil, nil, nil)
    end

    def user_scope_belongs_to_organization?
      return if user_scope_id.blank?

      current_organization.scopes.include? user_scope
    end

    def user_scope
      @user_scope ||= Decidim::Scope.find(user_scope_id) if user_scope_id.present?
    end
  end
end

Decidim::Initiatives::VoteForm.send(:include, VoteFormExtend)
