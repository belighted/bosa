# frozen_string_literal: true

require "active_support/concern"

module VoteCellExtend
  extend ActiveSupport::Concern

  included do
    def user_scope
      metadata[:user_scope]
    end

    def resident
      metadata[:resident]
    end
  end
end

Decidim::InitiativesVotes::VoteCell.send(:include, VoteCellExtend)
