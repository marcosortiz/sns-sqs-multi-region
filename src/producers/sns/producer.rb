require 'json'
require 'time'
require 'aws-sdk-sns'

class SnsProducer

  PRIMARY_ENV_KEY = 'primary'
  SECONDARY_ENV_KEY = 'secondary'

  def initialize(num_messages=50, batch_size=10, is_pramary_env=true)
    @num_messages = num_messages
    @batch_size = batch_size


    config_file = File.read(File.join(__dir__, '..', '..', '..', 'config', 'config.json'))
    config = JSON.parse(config_file)
    env = is_pramary_env ? PRIMARY_ENV_KEY : SECONDARY_ENV_KEY
    @region = config[env]['region']
    @topic_arn = config[env]['SnsTopicArn']
  end

  def send_messages
    sns = Aws::SNS::Client.new(region: @region)
    messages = []
    mutex = Mutex.new
    count = 0
    
    @num_messages.times do |i|
      job_id = "#{(Time.now.utc.iso8601(6))}|#{@num_messages}|#{@batch_size}"
      msg = { job_id: job_id, task_id: i + 1 }.to_json
      messages << msg
    end

    t0 = Time.now
    log "Sending #{@num_messages} messages in batchets of #{@batch_size} to topic #{@topic_arn}"
    messages.each_slice(@batch_size) do |batch|
      threads = []
      batch.each  do |message|
        t = Thread.new do      
          response = sns.publish({
            topic_arn: @topic_arn,
            message: message
          })
        end
        threads << t
      end
  
      threads.each do |t|
        t.join
        mutex.synchronize do
          count += 1
        end
      end
  
      elapsed_time = Time.now-t0
      log "Successfully sent #{count}/#{@num_messages} tasks in #{elapsed_time} seconds"
    end
    elapsed_time = Time.now-t0
    log("Total time: #{elapsed_time} seconds")
  end

  private

  def log(message)
    puts "#{Time.now.strftime('%H:%M:%S.%L')} - #{message}"
  end

end

IS_PRIMARY_ENV = true
NUM_MESSAGES = 5000
BATCH_SIZE = 500

producer = SnsProducer.new(NUM_MESSAGES, BATCH_SIZE, IS_PRIMARY_ENV)
producer.send_messages
