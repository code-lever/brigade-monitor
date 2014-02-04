module Brigade
  module Monitor

    class Fetcher

      def initialize(client, name, logger)
        @client = client
        @name = name
        @log = logger
      end

      def get_update
        version = @client.version
        summary = @client.summary
        devs = @client.devs
        pools = @client.pools

        # XXX check status replies on each command?

        update = {
            host: @name,
            uptime: summary.body[0]['Elapsed'],
            mhash: summary.body[0]['MHS av'],
            rejected_percent: summary.body[0]['Pool Rejected%'],
            api_version: version.body[0]['API'],
            cgminer_version: version.body[0]['CGMiner'],
            sgminer_version: version.body[0]['SGMiner'],
            asics: [],
            fpgas: [],
            gpus: [],
            pools: [],
            agent: {
                name: 'brigade-monitor-gem',
                platform: RUBY_PLATFORM,
                version: Brigade::Monitor::VERSION
            }
        }

        devs.body.each do |dev|
          if dev.has_key? 'GPU'
            update[:gpus] << {
                index: dev['GPU'],
                temperature: dev['Temperature'],
                fan_speed: dev['Fan Speed'],
                fan_percent: dev['Fan Percent'],
                gpu_clock: dev['GPU Clock'],
                memory_clock: dev['Memory Clock'],
                gpu_voltage: dev['GPU Voltage'],
                gpu_activity: dev['GPU Activity'],
                powertune: dev['Powertune'],
                enabled: dev['Enabled'] == 'Y',
                status: dev['Status'],
                uptime: dev['Device Elapsed'],
                mhash_average: dev['MHS av'],
                mhash_current: dev['MHS 5s'],
                accepted: dev['Accepted'],
                rejected: dev['Rejected'],
                hardware_errors: dev['Hardware Errors'],
                utility: dev['Utility'],
                intensity: dev['Intensity'],
                rejected_percent: dev['Device Rejected%'],
                last_share_pool: dev['Last Share Pool'],
                last_share_time: dev['Last Share Time'],
                total_mhash: dev['Total MH'],
                diff1_work: dev['Diff1 Work'],
                difficulty_accepted: dev['Difficulty Accepted'],
                difficulty_rejected: dev['Difficulty Rejected'],
                last_share_difficulty: dev['Last Share Difficulty'],
                last_valid_work: dev['Last Valid Work'],
            }
          elsif dev.has_key? 'ASC'
            update[:asics] << {
                index: dev['ASC'],
                temperature: dev['Temperature'],
                enabled: dev['Enabled'] == 'Y',
                status: dev['Status'],
                uptime: dev['Device Elapsed'],
                mhash_average: dev['MHS av'],
                mhash_current: dev['MHS 5s'],
                accepted: dev['Accepted'],
                rejected: dev['Rejected'],
                hardware_errors: dev['Hardware Errors'],
                utility: dev['Utility'],
                rejected_percent: dev['Device Rejected%'],
                last_share_pool: dev['Last Share Pool'],
                last_share_time: dev['Last Share Time'],
                total_mhash: dev['Total MH'],
                diff1_work: dev['Diff1 Work'],
                difficulty_accepted: dev['Difficulty Accepted'],
                difficulty_rejected: dev['Difficulty Rejected'],
                last_share_difficulty: dev['Last Share Difficulty'],
                last_valid_work: dev['Last Valid Work'],
            }
          elsif dev.has_key? 'PGA'
            update[:fpgas] << {
                index: dev['PGA'],
                temperature: dev['Temperature'],
                enabled: dev['Enabled'] == 'Y',
                status: dev['Status'],
                uptime: dev['Device Elapsed'],
                mhash_average: dev['MHS av'],
                mhash_current: dev['MHS 5s'],
                accepted: dev['Accepted'],
                rejected: dev['Rejected'],
                hardware_errors: dev['Hardware Errors'],
                utility: dev['Utility'],
                rejected_percent: dev['Device Rejected%'],
                last_share_pool: dev['Last Share Pool'],
                last_share_time: dev['Last Share Time'],
                total_mhash: dev['Total MH'],
                frequency: dev['Frequency'],
                diff1_work: dev['Diff1 Work'],
                difficulty_accepted: dev['Difficulty Accepted'],
                difficulty_rejected: dev['Difficulty Rejected'],
                last_share_difficulty: dev['Last Share Difficulty'],
                last_valid_work: dev['Last Valid Work'],
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
              priority: pool['Priority'],
              quota: pool['Quota'],
              longpoll: pool['Long Poll'] == 'Y',
              getworks: pool['Getworks'],
              accepted: pool['Accepted'],
              rejected: pool['Rejected'],
              works: pool['Works'],
              discarded: pool['Discarded'],
              stale: pool['Stale'],
              active: pool['Stratum Active'],
              rejected_percent: pool['Pool Rejected%']
          }
        end

        @log.debug("Built update: #{update}")
        update
      end

    end

  end
end
