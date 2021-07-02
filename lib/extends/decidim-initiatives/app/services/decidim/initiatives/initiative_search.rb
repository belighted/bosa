# frozen_string_literal: true

require "active_support/concern"

module InitiativeSearchExtend
  extend ActiveSupport::Concern

  included do

    def search_state
      ids = []
      ids += state.member?("accepted") ? query.accepted.ids : []
      ids += state.member?("rejected") ? query.rejected.ids : []
      ids += state.member?("answered") ? query.answered.ids : []
      ids += state.member?("open") ? query.open.ids : []
      ids += state.member?("closed") ? query.closed.ids : []
      ids += state.member?("examinated") ? query.examinated.ids : []
      ids += state.member?("debatted") ? query.debatted.ids : []
      ids += state.member?("classified") ? query.classified.ids : []

      query.where(id: ids)
    end

    def search_area_id
      return query if area_ids.include?("all")

      query.
        joins("JOIN decidim_initiatives_areas ON decidim_initiatives.id = decidim_initiatives_areas.decidim_initiative_id").
        where(decidim_initiatives_areas: {decidim_area_id: area_ids}).
        group("decidim_initiatives.id")
    end

  end
end

Decidim::Initiatives::InitiativeSearch.send(:include, InitiativeSearchExtend)
