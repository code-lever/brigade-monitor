require 'json'

module Brigade
  module Monitor

    class Monitor

      def initialize(key, miners, logger)
        @key = key
        @miners = miners.map do |m|
          fetcher = Brigade::Monitor::Fetcher.new(m[:client], m[:name], logger)
          { fetcher: fetcher }.merge(m)
        end
        puts @miners.inspect
        @log = logger
      end

      def run
        api = Brigade::Monitor::API.new(@key, @log)

        @log.info("Monitoring #{@miners.length} miners")
        loop do
          updates = []

          @miners.each do |miner|
            @log.debug("Beginning miner: #{miner}")

            begin
              updates << miner[:fetcher].get_update
            rescue Net::OpenTimeout => e
              @log.warn("Net::OpenTimeout building update for #{miner[:name]} (#{e})")
              # XXX put something in the update to indicate it barfed
            rescue Exception => e
              @log.error("Exception building update for #{miner[:name]} (#{e})")
              # XXX put something in the update to indicate it barfed
            end
          end

          if updates.empty?
            @log.info("Updates empty, not submitting")
          else
            @log.info("Updates available (#{updates.length}), submitting")
            begin
              tries ||= 3
              response = api.hosts(updates.to_json)
            rescue Exception => e
              @log.error("Exception submitting updates (#{e})")
              unless (tries -= 1).zero?
                @log.error('Retrying...')
                retry
              else
                @log.error('Giving up for this update...')
              end
            else
              if 401 == response.code
                @log.error('Unauthorized response submitting updates, check API key!')
                return
              end
              @log.info("Submitted updates (status: #{response.code})")
            end
          end

          sleep 60
        end
      end

    end

  end
end
