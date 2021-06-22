# frozen_string_literal: true

class CheckPublishedSuggestions < ApplicationJob
  def perform
    DecidimAws::Application.load_tasks
    Rake::Task["decidim_suggestions:check_published"].clear

    load Rails.root.join('lib', 'tasks', 'decidim_suggestions_extras.rake')
    Rake::Task['decidim_suggestions:check_published'].invoke
  end
end
