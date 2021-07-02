# frozen_string_literal: true

require "active_support/concern"

module InitiativesEngineExtend
  extend ActiveSupport::Concern

  included do
    routes do
      get "initiatives_authorization_creation_modal", to: "authorization_creation_modals#show"

      resources :initiative_types, only: [:show], path: "initiatives_types" do
        member do
          get "authorization_creation_modal", to: "authorization_creation_for_type_modals#show"
        end
      end
    end
  end
end

Decidim::Initiatives::Engine.send(:include, InitiativesEngineExtend)
