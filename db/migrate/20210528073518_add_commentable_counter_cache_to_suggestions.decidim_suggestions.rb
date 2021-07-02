# frozen_string_literal: true
# This migration comes from decidim_suggestions (originally 20210525080002)

class AddCommentableCounterCacheToSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_suggestions, :comments_count, :integer, null: false, default: 0, index: true
    Decidim::Suggestion.reset_column_information
    Decidim::Suggestion.find_each(&:update_comments_count)
  end
end
