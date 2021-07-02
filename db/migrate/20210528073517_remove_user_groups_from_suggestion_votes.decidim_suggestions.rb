# frozen_string_literal: true
# This migration comes from decidim_suggestions (originally 20210525080001)

class RemoveUserGroupsFromSuggestionVotes < ActiveRecord::Migration[5.2]
  def change
    remove_column :decidim_suggestions_votes, :decidim_user_group_id
  end
end
