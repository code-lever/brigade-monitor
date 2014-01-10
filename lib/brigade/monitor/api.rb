require 'httparty'

module Brigade
  module Monitor

    class API

      include HTTParty
      base_uri 'https://app.brigade.io/api/v1'

      def initialize(key)
        @key = key
      end

      def hosts(data)
        command('/hosts', updates: data)
      end

      private

      def command(command, params)
        params.merge!({ token: @key })
        self.class.post(command, query: params, verify: false)
      end

    end

  end
end
