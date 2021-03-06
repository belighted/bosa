# frozen_string_literal: true
# This migration comes from decidim_suggestions (originally 20201015141000)

class EnablePgTrgmExtensionForSuggestions < ActiveRecord::Migration[5.1]
  def change
    return if extension_enabled?("pg_trgm")

    begin
      # required so that test suite works in ci env
      enable_extension "pg_trgm"
    rescue StandardError
      raise <<-MSG.squish
        Decidim requires the pg_trgm extension to be enabled in your PostgreSQL.
        You can do so by running `CREATE EXTENSION IF NOT EXISTS "pg_trgm";` on the current DB as a PostgreSQL
        super user.
      MSG
    end
  end
end
