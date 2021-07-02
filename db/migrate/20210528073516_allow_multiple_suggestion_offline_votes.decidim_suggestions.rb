# frozen_string_literal: true
# This migration comes from decidim_suggestions (originally 20210525073003)

class AllowMultipleSuggestionOfflineVotes < ActiveRecord::Migration[5.2]
  class SuggestionsTypeScope < ApplicationRecord
    self.table_name = :decidim_suggestions_type_scopes
  end

  class Suggestion < ApplicationRecord
    self.table_name = :decidim_suggestions
    belongs_to :scoped_type, class_name: "SuggestionsTypeScope"
  end

  def change
    rename_column :decidim_suggestions, :offline_votes, :old_offline_votes
    add_column :decidim_suggestions, :offline_votes, :jsonb, default: {}

    Suggestion.reset_column_information

    Suggestion.includes(:scoped_type).find_each do |suggestion|
      scope_key = suggestion.scoped_type.decidim_scopes_id || "global"

      offline_votes = {
        scope_key => suggestion.old_offline_votes.to_i,
        "total" => suggestion.old_offline_votes.to_i
      }

      # rubocop:disable Rails/SkipsModelValidations
      suggestion.update_column(:offline_votes, offline_votes)
      # rubocop:enable Rails/SkipsModelValidations
    end

    remove_column :decidim_suggestions, :old_offline_votes
  end
end
