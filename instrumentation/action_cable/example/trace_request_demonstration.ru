# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'

  gem 'rails'
  gem 'puma'
  gem 'redis'
  gem 'opentelemetry-sdk'
  gem 'opentelemetry-instrumentation-rails', path: '../../rails'
  gem 'opentelemetry-instrumentation-action_cable', path: '../'
end

require 'active_support/railtie'
require 'action_controller/railtie'
require 'action_cable/engine'

# TraceRequestApp is a minimal Rails application inspired by the Rails
# bug report template for action controller.
# The configuration is compatible with Rails 6.0
class TraceRequestApp < Rails::Application
  config.root = __dir__
  config.hosts << "example.org"
  config.session_store :cookie_store, key: "cookie_store_key"
  secrets.secret_key_base = "secret_key_base"

  config.eager_load = false

  config.logger = Logger.new($stdout)
  Rails.logger = config.logger

  config.action_cable.cable = { adapter: "async" }
  config.action_cable.mount_path = "/cable"

  # cable_config = ActionCable::Server::Configuration.new
  # cable_config.cable = { adapter: "redis", channel_prefix: "custom_" }
  # cable_config = config.logger

  # ActionCable.server.config = ActionCable::Server::Base.new(config: cable_config)
  # ActionCable.server.config = cable_config

  ActionCable.server.config.cable = { adapter: "async" }
  ActionCable.server.config.logger = config.logger

  routes.draw do
    mount ActionCable.server => '/cable'

    get "/" => "test#index"
  end
end

# A minimal test controller
class TestController < ActionController::Base
  include Rails.application.routes.url_helpers

  def index
    ActionCable.server.broadcast("chat_switch", { body: "This Room is Best Room." })
    render plain: "Home"
  end
end

# A minimal test channel
class TestChannel < ActionCable::Channel::Base
  def subscribed
    puts "Chama"
    stream_from "chat_#{params[:room]}"
  end
end

# Simple setup for demonstration purposes, simple span processor should not be
# used in a production environment
span_processor = OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
  OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
)

OpenTelemetry::SDK.configure do |c|
  # At present, the Rails instrumentation is required.
  c.use 'OpenTelemetry::Instrumentation::Rails'
  c.use 'OpenTelemetry::Instrumentation::ActionCable'
  c.add_span_processor(span_processor)
end

run Rails.application

# To run this example run the `rackup` command with this file
# Example: rackup trace_request_demonstration.ru
# Navigate to http://localhost:9292/
# Spans for the requests will appear in the console
