# frozen_string_literal: true
# This migration comes from decidim_suggestions (originally 20210525080004)

class AddFollowableCounterCacheToSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_suggestions, :follows_count, :integer, null: false, default: 0, index: true

    reversible do |dir|
      dir.up do
        Decidim::Suggestion.reset_column_information
        Decidim::Suggestion.find_each do |record|
          record.class.reset_counters(record.id, :follows)
        end
      end
    end
  end
end
