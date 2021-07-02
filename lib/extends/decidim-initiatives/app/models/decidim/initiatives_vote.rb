# frozen_string_literal: true

require "active_support/concern"

module InitiativesVoteExtend
  extend ActiveSupport::Concern

  included do
    def self.user_collection(author)
      where(decidim_author_id: author.id)
    end

    def self.export_serializer
      Decidim::Initiatives::DataPortabilityInitiativesVoteSerializer
    end

    def self.data_portability_images(user); end
  end
end

Decidim::InitiativesVote.send(:include, InitiativesVoteExtend)
