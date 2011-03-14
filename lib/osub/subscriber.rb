require 'net/http'
require 'uri'

module OSub
  class Subscription
    def initialize(callback_url, topic_url)
      @callback_url = callback_url
      @topic_url = topic_url
    end

    # Subscribe to the topic through the given hub.
    def subscribe(hub_url = @topic_url)
      change_subscription(:subscribe, hub_url)
    end

    # Unsubscribe to the topic through the given hub.
    def unsubscribe(hub_url = @topic_url)
      change_subscription(:unsubscribe, hub_url)
    end

    def change_subscription(mode, hub_url)
      res = Net::HTTP.post_form(URI.parse(hub_url),
                                { 'hub.mode' => mode.to_s,
                                  'hub.callback' => @callback_url,
                                  'hub.verify' => 'async',
                                  'hub.verify_token' => '',
                                  'hub.lease_seconds' => '',
                                  'hub.secret' => '',
                                  'hub.topic' => @topic_url})
    end

    def perform_challenge(challenge_code)
      {:body => challenge_code, :status => 200}
    end
  end

  module Subscriptions
    def Subscriptions.new(callback_url, topic_url)
      if not defined?(@@instances)
        @@instances = {}
      end

      if @@instances[topic_url] == nil
        sub = OSub::Subscription.new(callback_url, topic_url)
        @@instances[topic_url] = sub
      end

      @@instances[topic_url]
    end

    def Subscriptions.[](topic_url)
      return nil if not defined?(@@instances)
      @@instances[topic_url]
    end
  end
end
