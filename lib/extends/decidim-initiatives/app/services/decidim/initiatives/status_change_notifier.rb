# frozen_string_literal: true

require "active_support/concern"

module StatusChangeNotifierExtend
  extend ActiveSupport::Concern

  included do
    def notify
      notify_initiative_creation if initiative.created?
      notify_validating_initiative if initiative.validating?
      notify_validating_result if initiative.published? || initiative.discarded?
      notify_support_result if initiative.rejected? || initiative.accepted?
      notify_manual_change if initiative.classified? || initiative.examinated? || initiative.debatted?
    end

    private

    def notify_validating_result
      notify_committee_members
      notify_author
    end

    def notify_support_result
      notify_followers
      notify_committee_members
      notify_author
    end

    def notify_manual_change
      notify_followers
      notify_committee_members
      notify_author
    end

    def notify_committee_members
      initiative.committee_members.approved.each do |committee_member|
        next unless initiative.author != committee_member.user

        Decidim::Initiatives::InitiativesMailer
          .notify_state_change(initiative, committee_member.user)
          .deliver_later(wait: 10.seconds)
      end
    end

    def notify_followers
      initiative.followers.each do |follower|
        next unless initiative.author != follower

        Decidim::Initiatives::InitiativesMailer
          .notify_state_change(initiative, follower)
          .deliver_later(wait: 10.seconds)
      end
    end

    def notify_author
      Decidim::Initiatives::InitiativesMailer
        .notify_state_change(initiative, initiative.author)
        .deliver_later(wait: 10.seconds)
    end
  end
end

Decidim::Initiatives::StatusChangeNotifier.send(:include, StatusChangeNotifierExtend)
