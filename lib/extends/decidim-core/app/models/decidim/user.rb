# frozen_string_literal: true

require "active_support/concern"

module UserExtend
  extend ActiveSupport::Concern

  included do
    clear_validators!
    validates :name, presence: true, unless: -> { deleted? }
    validates :nickname,
              presence: true,
              format: { with: Decidim::User::REGEXP_NICKNAME },
              length: { maximum: Decidim::User.nickname_max_length },
              unless: -> { deleted? || managed? }
    validates :locale, inclusion: { in: :available_locales }, allow_blank: true
    validates :tos_agreement, acceptance: true, allow_nil: true, on: :create
    validates :tos_agreement, acceptance: true, if: :user_invited?
    validates :email, :nickname, uniqueness: { scope: :organization }, unless: -> { deleted? || managed? || nickname.blank? || email.blank? }

    validate :all_roles_are_valid

    def active_for_authentication?
      super
    end

    def after_confirmation
      return if skip_after_confirmation?
      return unless organization.send_welcome_notification?

      Decidim::EventsManager.publish(
        event: "decidim.events.core.welcome_notification",
        event_class: Decidim::WelcomeNotificationEvent,
        resource: self,
        affected_users: [self]
      )
    end

    def skip_reconfirmation!
      @skip_after_confirmation = true
      @bypass_confirmation_postpone = true
    end

    def skip_after_confirmation?
      defined?(@skip_after_confirmation) && @skip_after_confirmation
    end
  end
end

Decidim::User.send(:include, UserExtend)
