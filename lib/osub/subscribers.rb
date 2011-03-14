require_relative 'subscription'

module OSub
  module Subscribers
    def Subscribers.new(callback_url, topic_url, secret = nil)
      if not defined?(@@instances)
        @@instances = {}
      end

      if @@instances[topic_url] == nil
        sub = OSub::Subscription.new(callback_url, topic_url, secret)
        @@instances[topic_url] = sub
      end

      @@instances[topic_url]
    end

    def Subscribers.[](topic_url)
      return nil if not defined?(@@instances)
      @@instances[topic_url]
    end
  end
end
