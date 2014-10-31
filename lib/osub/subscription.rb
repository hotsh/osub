require 'net/http'
require 'uri'

require 'ostatus'
require 'hmac-sha1'

module OSub
  class Subscription
    attr_reader :callback_url
    attr_reader :topic_url

    def initialize(callback_url, topic_url, secret = nil)
      @tokens = []

      secret = "" if secret == nil
      @secret = secret.to_s

      @callback_url = callback_url
      @topic_url = topic_url
    end

    # Actively searches for hubs by talking to publisher directly
    def hubs
      OStatus::Feed.from_url(topic_url).hubs
    end

    # Subscribe to the topic through the given hub.
    def subscribe(hub_url, token = nil)
      if token != nil
        @tokens << token.to_s
      end
      change_subscription(:subscribe, hub_url, token)
    end

    # Unsubscribe to the topic through the given hub.
    def unsubscribe(hub_url, token = nil)
      if token != nil
        @tokens << token.to_s
      end
      change_subscription(:unsubscribe, hub_url, token)
    end

    def change_subscription(mode, hub_url, token, redirect_limit = 10)
      hub_uri = URI.parse(hub_url)

      req = Net::HTTP::Post.new(hub_uri.request_uri)
      req.set_form_data({
        'hub.mode' => mode.to_s,
        'hub.callback' => @callback_url,
        'hub.verify' => 'async',
        'hub.verify_token' => token,
        'hub.lease_seconds' => '',
        'hub.secret' => @secret,
        'hub.topic' => @topic_url
      })

      http = Net::HTTP.new(hub_uri.hostname, hub_uri.port)
      if hub_uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      response = http.request(req)

      if response.is_a?(Net::HTTPRedirection) && redirect_limit > 0
        location = response['location']
        self.change_subscription(mode, hub_url, token, redirect_limit - 1)
      else
        response
      end

    rescue OpenSSL::SSL::SSLError
      return nil
    end

    def verify_subscription(token)
      result = @tokens.index(token) != nil
      @tokens.delete(token)

      result
    end

    def verify_content(body, signature)
      hmac = HMAC::SHA1.hexdigest(@secret, body)
      check = "sha1=" + hmac
      check == signature
    end

    def perform_challenge(challenge_code)
      {:body => challenge_code, :status => 200}
    end
  end
end
