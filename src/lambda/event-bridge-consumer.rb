def handler(event:, context:)
    current_time = (Time.now.to_f*1000).to_i
    puts "Received event: #{event}"

    process_event(event, current_time)
    
    # Return a response
    {
      statusCode: 200,
      body: JSON.generate({
        message: 'Event processed successfully',
        eventTime: event['time']
      })
    }
end

def process_event(event, current_time)
    event_time = (Time.parse(event['time']).to_f * 1000).to_i
    recorded_at = event['detail']['recorded_at']
    producer_to_eb_latency = current_time - recorded_at
    eb_to_lambda_latency = current_time - event_time
    lambda_to_code_latency = (Time.now.to_f * 1000).to_i - current_time

    puts "recorded_at: #{recorded_at} (#{recorded_at.class})"
    puts "event_time: #{event_time} (#{event_time.class})"
    puts "current_time: #{current_time} (#{current_time.class})"
    puts "producer_to_eb_latency: #{producer_to_eb_latency}"
    puts "eb_to_lambda_latency: #{eb_to_lambda_latency}"
    puts "lambda_to_code_latency: #{lambda_to_code_latency}"
end
  