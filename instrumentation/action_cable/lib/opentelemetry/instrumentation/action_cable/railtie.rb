# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module ActionCable
      SUBSCRIPTIONS = %w[
        perform_action.action_cable
        transmit.action_cable
        transmit_subscription_confirmation.action_cable
        transmit_subscription_confirmation.action_cable
        broadcast.action_cable
      ].freeze

      # This Railtie sets up subscriptions to relevant ActionCable notifications
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          ::OpenTelemetry::Instrumentation::ActiveSupport::Instrumentation.instance.install({})

          SUBSCRIPTIONS.each do |subscription_name|
            config = ActionCable::Instrumentation.instance.config
            ::OpenTelemetry::Instrumentation::ActiveSupport.subscribe(
              ActionCable::Instrumentation.instance.tracer,
              subscription_name,
              config[:notification_payload_transform],
              config[:disallowed_notification_payload_keys]
            )
          end
        end
      end
    end
  end
end
