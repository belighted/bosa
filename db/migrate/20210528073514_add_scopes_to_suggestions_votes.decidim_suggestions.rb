# frozen_string_literal: true
# This migration comes from decidim_suggestions (originally 20210525073001)

class AddScopesToSuggestionsVotes < ActiveRecord::Migration[5.2]
  class SuggestionVote < ApplicationRecord
    self.table_name = :decidim_suggestions_votes
    belongs_to :suggestion, foreign_key: "decidim_suggestion_id", class_name: "Suggestion"
  end

  class Suggestion < ApplicationRecord
    self.table_name = :decidim_suggestions
    belongs_to :scoped_type, class_name: "SuggestionsTypeScope"
  end

  class SuggestionsTypeScope < ApplicationRecord
    self.table_name = :decidim_suggestions_type_scopes
  end

  def change
    add_column :decidim_suggestions_votes, :decidim_scope_id, :integer

    SuggestionVote.reset_column_information

    SuggestionVote.includes(suggestion: :scoped_type).find_each do |vote|
      vote.decidim_scope_id = vote.suggestion.scoped_type.decidim_scopes_id
      vote.save!
    end
  end
end
