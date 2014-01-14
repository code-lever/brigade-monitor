require 'httparty'

module Brigade
  module Monitor

    class API

      include HTTParty
      base_uri 'https://app.brigade.io/api/v1'

      def initialize(key, logger)
        @key = key
        @log = logger
      end

      def hosts(data)
        command('/hosts', updates: data)
      end

      private

      def command(command, params)
        @log.debug("Posting command: #{command}, params: #{params}")
        self.class.post(command, query: params.merge({ token: @key }), verify: false)
      end

    end

  end
end
