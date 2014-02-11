require 'httparty'

module Brigade
  module Monitor

    class API

      include HTTParty
      base_uri 'https://www.brigade.io/api/v1'

      def initialize(key, logger)
        @key = key
        @log = logger
      end

      def hosts(data)
        command('/hosts', updates: data)
      end

      private

      def command(command, params)
        @log.debug("Posting command: #{command}, data: #{params}")
        self.class.post(command, body: params.merge({ token: @key }))
      end

    end

  end
end
