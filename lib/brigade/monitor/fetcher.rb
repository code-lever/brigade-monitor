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

        update = host_info(summary, version)

        devs.body.each do |dev|
          if dev.has_key? 'GPU'
            update[:gpus] << gpu_info(dev)
          elsif dev.has_key? 'ASC'
            update[:asics] << asic_info(dev)
          elsif dev.has_key? 'PGA'
            update[:fpgas] << fpga_info(dev)
          else
            @log.warn("Skipped unknown device: #{dev}")
          end
        end

        pools.body.each do |pool|
          update[:pools] << pool_info(pool)
        end

        @log.debug("Built update: #{update}")
        update
      end

      private

      def host_info(summary, version)
        {
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
      end

      def asic_info(device)
        {
          index: device['ASC'],
          temperature: device['Temperature'],
          enabled: device['Enabled'] == 'Y',
          status: device['Status'],
          uptime: device['Device Elapsed'],
          mhash_average: device['MHS av'],
          mhash_current: device['MHS 5s'],
          accepted: device['Accepted'],
          rejected: device['Rejected'],
          hardware_errors: device['Hardware Errors'],
          utility: device['Utility'],
          rejected_percent: device['Device Rejected%'],
          last_share_pool: device['Last Share Pool'],
          last_share_time: device['Last Share Time'],
          total_mhash: device['Total MH'],
          diff1_work: device['Diff1 Work'],
          difficulty_accepted: device['Difficulty Accepted'],
          difficulty_rejected: device['Difficulty Rejected'],
          last_share_difficulty: device['Last Share Difficulty'],
          last_valid_work: device['Last Valid Work'],
        }
      end

      def fpga_info(device)
        {
          index: device['PGA'],
          temperature: device['Temperature'],
          enabled: device['Enabled'] == 'Y',
          status: device['Status'],
          uptime: device['Device Elapsed'],
          mhash_average: device['MHS av'],
          mhash_current: device['MHS 5s'],
          accepted: device['Accepted'],
          rejected: device['Rejected'],
          hardware_errors: device['Hardware Errors'],
          utility: device['Utility'],
          rejected_percent: device['Device Rejected%'],
          last_share_pool: device['Last Share Pool'],
          last_share_time: device['Last Share Time'],
          total_mhash: device['Total MH'],
          frequency: device['Frequency'],
          diff1_work: device['Diff1 Work'],
          difficulty_accepted: device['Difficulty Accepted'],
          difficulty_rejected: device['Difficulty Rejected'],
          last_share_difficulty: device['Last Share Difficulty'],
          last_valid_work: device['Last Valid Work'],
        }
      end

      def gpu_info(device)
        {
          index: device['GPU'],
          temperature: device['Temperature'],
          fan_speed: device['Fan Speed'],
          fan_percent: device['Fan Percent'],
          gpu_clock: device['GPU Clock'],
          memory_clock: device['Memory Clock'],
          gpu_voltage: device['GPU Voltage'],
          gpu_activity: device['GPU Activity'],
          powertune: device['Powertune'],
          enabled: device['Enabled'] == 'Y',
          status: device['Status'],
          uptime: device['Device Elapsed'],
          mhash_average: device['MHS av'],
          mhash_current: device['MHS 5s'],
          accepted: device['Accepted'],
          rejected: device['Rejected'],
          hardware_errors: device['Hardware Errors'],
          utility: device['Utility'],
          intensity: device['Intensity'],
          rejected_percent: device['Device Rejected%'],
          last_share_pool: device['Last Share Pool'],
          last_share_time: device['Last Share Time'],
          total_mhash: device['Total MH'],
          diff1_work: device['Diff1 Work'],
          difficulty_accepted: device['Difficulty Accepted'],
          difficulty_rejected: device['Difficulty Rejected'],
          last_share_difficulty: device['Last Share Difficulty'],
          last_valid_work: device['Last Valid Work'],
        }
      end

      def pool_info(pool)
        {
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

    end

  end
end
