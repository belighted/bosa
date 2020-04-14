# frozen_string_literal: true
require "active_support/concern"

module CreateOmniauthRegistrationExtend
  extend ActiveSupport::Concern

  included do

    def call
      verify_oauth_signature!

      begin
        if existing_identity
          user = existing_identity.user
          verify_user_confirmed(user)

          return broadcast(:ok, user)
        end

        if request.path.end_with?("france_connect_profile/callback")
          return broadcast(:error, user)
        end

        return broadcast(:invalid) if form.invalid?

        transaction do
          create_or_find_user
          @identity = create_identity
        end
        @user.after_confirmation if @after_confirmation
        trigger_omniauth_registration

        broadcast(:ok, @user)
      rescue ActiveRecord::RecordInvalid => e
        broadcast(:error, e.record)
      end
    end

    def create_or_find_user
      generated_password = SecureRandom.hex

      @user = Decidim::User.find_or_initialize_by(
        email: verified_email,
        organization: organization
      )

      if !@user.persisted? || @user.invited_to_sign_up?
        @user.email = (verified_email || form.email)
        @user.name = form.name
        @user.nickname = form.normalized_nickname
        @user.newsletter_notifications_at = nil
        @user.email_on_notification = true
        @user.password = generated_password
        @user.password_confirmation = generated_password

        @user.full_address = form.full_address
        @user.custom_agreement_at = DateTime.now if form.custom_agreement

        # TODO: raise ActiveRecord::RecordInvalid because of quality setting on uploader, this line is a quick fix
        @user.remote_avatar_url = form.avatar_url if form.avatar_url.present? && !form.avatar_url.end_with?("svg")
        @user.skip_confirmation! if verified_email
        @user.accept_invitation if @user.invited_to_sign_up?
      end

      @user.tos_agreement = "1"
      @user.save!
    end

  end
end

Decidim::CreateOmniauthRegistration.send(:include, CreateOmniauthRegistrationExtend)