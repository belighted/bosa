# frozen_string_literal: true

require "active_support/concern"

module VoteInitiativeExtend
  extend ActiveSupport::Concern

  included do

    # Executes the command. Broadcasts these events:
    #
    # - :ok when everything is valid, together with the proposal vote.
    # - :invalid if the form wasn't valid and we couldn't proceed.
    #
    # Returns nothing.
    def call
      return broadcast(:invalid) if form.invalid?

      percentage_before = initiative.percentage
      scopes_percentages_before = {}
      initiative.votable_initiative_type_scopes.each do |type_scope|
        scopes_percentages_before[type_scope.id] = initiative.percentage_for(type_scope.scope)
      end

      Decidim::Initiative.transaction do
        create_votes
      end

      percentage_after = initiative.reload.percentage

      send_notification
      notify_percentage_change(percentage_before, percentage_after)
      notify_support_threshold_reached(percentage_before, percentage_after)
      initiative.votable_initiative_type_scopes.each do |type_scope|
        notify_support_threshold_reached_for(type_scope, scopes_percentages_before[type_scope.id], initiative.percentage_for(type_scope.scope))
      end

      broadcast(:ok, votes)
    end

    private

    def notify_support_threshold_reached_for(type_scope, before, after)
      # Don't need to notify for global scopes
      return if type_scope.global_scope?

      # Don't need to notify if threshold has already been reached
      return if before == after || after != 100

      Decidim::EventsManager.publish(
        event: "decidim.events.initiatives.support_threshold_reached_for_scope",
        event_class: Decidim::Initiatives::SupportThresholdReachedForScopeEvent,
        resource: initiative,
        affected_users: [initiative.author],
        extra: {
          scope: type_scope.scope
        }
      )
      Decidim::EventsManager.publish(
        event: "decidim.events.initiatives.admin.support_threshold_reached_for_scope",
        event_class: Decidim::Initiatives::Admin::SupportThresholdReachedForScopeEvent,
        resource: initiative,
        affected_users: organization_admins,
        extra: {
          scope: type_scope.scope
        }
      )
    end

  end
end

Decidim::Initiatives::VoteInitiative.send(:include, VoteInitiativeExtend)
