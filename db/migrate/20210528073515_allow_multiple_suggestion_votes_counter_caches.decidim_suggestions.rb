# frozen_string_literal: true
# This migration comes from decidim_suggestions (originally 20210525073002)

class AllowMultipleSuggestionVotesCounterCaches < ActiveRecord::Migration[5.2]
  class SuggestionVote < ApplicationRecord
    self.table_name = :decidim_suggestions_votes
  end

  class Suggestion < ApplicationRecord
    self.table_name = :decidim_suggestions
    has_many :votes, foreign_key: "decidim_suggestion_id", class_name: "SuggestionVote"
  end

  def change
    add_column :decidim_suggestions, :online_votes, :jsonb, default: {}

    Suggestion.reset_column_information

    Suggestion.find_each do |suggestion|
      online_votes = suggestion.votes.group(:decidim_scope_id).count.each_with_object({}) do |(scope_id, count), counters|
        counters[scope_id || "global"] = count
        counters["total"] = count
      end

      # rubocop:disable Rails/SkipsModelValidations
      suggestion.update_column("online_votes", online_votes)
      # rubocop:enable Rails/SkipsModelValidations
    end

    remove_column :decidim_suggestions, :suggestion_supports_count
    remove_column :decidim_suggestions, :suggestion_votes_count
  end
end
