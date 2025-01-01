require 'json'
require 'time'
require 'aws-sdk-sqs'

class SqsProducer
  PRIMARY_ENV_KEY   = 'primary'
  SECONDARY_ENV_KEY = 'secondary'

  def initialize(is_pramary_env=true)
    config_file = File.read(File.join(__dir__, '..', '..', '..', 'config', 'config.json'))
    config = JSON.parse(config_file)
    env = is_pramary_env ? PRIMARY_ENV_KEY : SECONDARY_ENV_KEY
    @region = config[env]['region']
    @queue_url = config[env]['ActiveQueueUrl']

    @sqs = Aws::SQS::Client.new(region: @region)
  end

  def send_message
    recorded_at = (Time.now.utc.to_f*1000).to_i
    log('Sending message ...')

    message = JSON.generate({
      recorded_at: recorded_at
    })
    response = @sqs.send_message({
        queue_url: @queue_url,
        message_body: message
    })

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
p = SqsProducer.new(IS_PRIMARY_ENV)
while true do
    sleep(1 - Time.now.to_f % 1)
    p.send_message
end