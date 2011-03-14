require 'net/http'
require 'uri'

require 'hmac-sha1'

module OSub
  class Subscription
    attr_reader :callback_url
    attr_reader :topic_url

    def initialize(callback_url, topic_url, secret = nil, token = nil)
      token = "" if token == nil
      @token = token.to_s

      secret = "" if secret == nil
      @secret = secret.to_s

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
                                  'hub.verify_token' => @token,
                                  'hub.lease_seconds' => '',
                                  'hub.secret' => @secret,
                                  'hub.topic' => @topic_url})
    end

    def verify(body, signature)
      hmac = HMAC::SHA1.hexdigest(@secret, body)
      check = "sha1=" + hmac
      check == signature
    end

    def perform_challenge(challenge_code)
      {:body => challenge_code, :status => 200}
    end
  end

  module Subscriptions
    def Subscriptions.new(callback_url, topic_url, secret = nil, token = nil)
      if not defined?(@@instances)
        @@instances = {}
      end

      if @@instances[topic_url] == nil
        sub = OSub::Subscription.new(callback_url, topic_url, secret, token)
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
