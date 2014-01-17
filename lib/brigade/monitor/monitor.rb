require 'json'

module Brigade
  module Monitor

    class Monitor

      def initialize(key, miners, logger)
        @key = key
        @miners = miners
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
              updates << get_update(miner)
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

      def get_update(miner)
        version = miner[:client].version
        summary = miner[:client].summary
        devs = miner[:client].devs
        pools = miner[:client].pools

        # XXX check status replies on each command?

        update = {
          host: miner[:name],
          uptime: summary.body[0]['Elapsed'],
          mhash: summary.body[0]['MHS av'],
          rejectpct: summary.body[0]['Pool Rejected%'],
          'api-version' => version.body[0]['API'],
          'cgminer-version' => version.body[0]['CGMiner'],
          'sgminer-version' => version.body[0]['SGMiner'],
          asics: [],
          fpgas: [],
          gpus: [],
          pools: [],
          agent: {
            name: 'brigade-monitor-gem',
            version: Brigade::Monitor::VERSION
          }
        }

        devs.body.each do |dev|
          if dev.has_key? 'GPU'
            update[:gpus] << {
              index: dev['GPU'],
              temperature: dev['Temperature'],
              enabled: dev['Enabled'] == 'Y',
              status: dev['Status'],
              uptime: dev['Device Elapsed'],
              mhash: dev['MHS av'],
              hwerrors: dev['Hardware Errors'],
              rejectpct: dev['Device Rejected%']
            }
          elsif dev.has_key? 'ASC'
            update[:asics] << {
              index: dev['ASC'],
              temperature: dev['Temperature'],
              enabled: dev['Enabled'] == 'Y',
              status: dev['Status'],
              uptime: dev['Device Elapsed'],
              mhash: dev['MHS av'],
              hwerrors: dev['Hardware Errors'],
              rejectpct: dev['Device Rejected%']
            }
          elsif dev.has_key? 'PGA'
            update[:fpgas] << {
              index: dev['PGA'],
              temperature: dev['Temperature'],
              enabled: dev['Enabled'] == 'Y',
              status: dev['Status'],
              uptime: dev['Device Elapsed'],
              mhash: dev['MHS av'],
              hwerrors: dev['Hardware Errors'],
              rejectpct: dev['Device Rejected%']
            }
          else
            @log.warn("Skipped unknown device: #{dev}")
          end
        end

        pools.body.each do |pool|
          update[:pools] << {
            index: pool['POOL'],
            url: pool['URL'],
            status: pool['Status'],
            active: pool['Stratum Active'],
            rejectpct: pool['Pool Rejected%']
          }
        end

        @log.debug("Built update: #{update}")
        update
      end

    end

  end
end
