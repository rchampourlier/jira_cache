# frozen_string_literal: true
require "sequel"

module JiraCache
  module Data
    DATABASE_URL = ENV["DATABASE_URL"]
    DB = Sequel.connect(DATABASE_URL)
    DB.extension :pg_array, :pg_json
  end
end
