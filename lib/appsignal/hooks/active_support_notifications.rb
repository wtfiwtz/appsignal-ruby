module Appsignal
  class Hooks
    class ActiveSupportNotificationsHook < Appsignal::Hooks::Hook
      register :active_support_notifications

      def dependencies_present?
        defined?(::ActiveSupport::Notifications)
      end

      def install
        ::ActiveSupport::Notifications.class_eval do
          class << self
            alias instrument_without_appsignal instrument

            def instrument(name, payload={}, &block)
              transaction = Appsignal::Transaction.current

              transaction.start_event

              instrument_without_appsignal(name, payload, &block)

              title, body, body_format = Appsignal::EventFormatter.format(name, payload)
              transaction.finish_event(
                name,
                title,
                body,
                body_format
              )
            end
          end
        end
      end
    end
  end
end
