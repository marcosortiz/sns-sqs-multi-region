require 'json'
require 'time'
require 'aws-sdk-eventbridge'

class EventBridgeProducer
  PRIMARY_ENV_KEY   = 'primary'
  SECONDARY_ENV_KEY = 'secondary'

  def initialize(is_primary_env=true)
    config_file = File.read(File.join(__dir__, '..', '..', '..', 'config', 'config.json'))
    config = JSON.parse(config_file)
    env = is_primary_env ? PRIMARY_ENV_KEY : SECONDARY_ENV_KEY
    @region = config[env]['region']
    @event_bus_name = config[env]['EventBusName']

    @eventbridge = Aws::EventBridge::Client.new(region: @region)
  end

  def send_message
    recorded_at = (Time.now.utc.to_f*1000).to_i
    log('Sending message to EventBridge...')

    event_detail = {
      recorded_at: recorded_at
    }

    response = @eventbridge.put_events({
      entries: [
        {
          time: Time.now,
          source: 'custom.events',
          detail_type: 'CustomEvent',
          detail: event_detail.to_json,
          event_bus_name: @event_bus_name
        }
      ]
    })

    if response.failed_entry_count > 0
      log("Failed to send #{response.failed_entry_count} events")
    end
  end

  private

  def sleep_until_next_second
    current_time = Time.now
    next_second = Time.at((current_time.to_f + 1).floor)
    sleep_time = next_second - current_time

    sleep(sleep_time)
  end

  def log(message)
    puts "[#{Time.now.strftime("%H:%M:%S.%L")}] #{message}"
  end
end

IS_PRIMARY_ENV = true
p = EventBridgeProducer.new(IS_PRIMARY_ENV)
while true do
  sleep(1 - Time.now.to_f % 1)
  p.send_message
end
