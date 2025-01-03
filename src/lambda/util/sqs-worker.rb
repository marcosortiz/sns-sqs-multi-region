require 'time'

class SqsWorker

    def batch_process_records(records, max_retries=2, thread_count=5)
        t0 = Time.now
        failed_records = []
        producer_to_sns_latencies = []
        producer_to_sqs_latencies = []
        sns_to_sqs_latencies = []
        sqs_to_lambda_lacencies = []
        lambda_to_code_latencies = []
        latencies = []
        failed_count = 0
        mutex = Mutex.new
      
        process_records = ->(recs) do
          threads = []
          recs.each_slice((recs.size.to_f / thread_count).ceil) do |slice|
            threads << Thread.new do
              current_time = (Time.now.to_f*1000).to_i
              slice.each do |record|
                body = JSON.parse(record['body'])
                is_sns_originated = is_sns_originated(body)
                message = parse_message(body, is_sns_originated)

                calculate_latencies = calculate_latencies(record, body, message, is_sns_originated, current_time)
                
                mutex.synchronize do
                  if is_sns_originated
                    producer_to_sns_latencies << calculate_latencies[:producer_to_sns_latency]
                    sns_to_sqs_latencies << calculate_latencies[:sns_to_sqs_latency]
                  else
                    producer_to_sqs_latencies << calculate_latencies[:producer_to_sqs_latency]
                  end
                  sqs_to_lambda_lacencies << calculate_latencies[:sqs_to_lambda_lacency]
                  lambda_to_code_latencies << calculate_latencies[:lambda_to_code_latency]
                  latencies << calculate_latencies[:latency]
                end
                
                success = process_record(message)
                unless success
                  mutex.synchronize do
                    failed_records << record
                    failed_count += 1
                  end
                end
              end
            end
          end
          threads.each do |t|
            t.join
          end
        end
      
        # Initial processing
        process_records.call(records)
      
        # Retry logic
        max_retries.times do |retry_count|
          break if failed_records.empty?
      
          failed_count = 0
          puts("Retry pass #{retry_count + 1}/#{max_retries}")
          retry_records = failed_records.dup
          failed_records.clear
      
          process_records.call(retry_records)
        end
      
        elapsed_time = Time.now - t0

        return_hash = {
          report: {
            batch_size: records.length,
            success_count: records.length - failed_count,
            failed_count: failed_count,
            retries: [max_retries, failed_records.empty? ? max_retries : max_retries - 1].min,
            duration: elapsed_time,
            process_rate: (records.length - failed_count) / elapsed_time,
            sqs_to_lambda_lacency: sqs_to_lambda_lacencies.max,
            lambda_to_code_latency: lambda_to_code_latencies.max,
            latency: latencies.max
          },
          failed_records: failed_records
        }
      
        return_hash[:report][:producer_to_sns_latency] = producer_to_sns_latencies.max unless producer_to_sns_latencies.empty?
        return_hash[:report][:producer_to_sqs_latency] = producer_to_sqs_latencies.max unless producer_to_sqs_latencies.empty?
        return_hash[:report][:sns_to_sqs_latency] = sns_to_sqs_latencies.max unless sns_to_sqs_latencies.empty?
        return_hash
    end
      

    private

    def process_record(message, retrying=false)
        begin
            puts(message)
            return true
        rescue StandardError => e
            puts("Error: #{e.message}")
            return false
        end
    end

    def is_sns_originated(parsed_json_body)
      parsed_json_body['Type'] == 'Notification' && parsed_json_body['TopicArn']
    end

    def parse_message(parsed_json_body, is_sns_originated)
      message = parsed_json_body
      message = JSON.parse(parsed_json_body['Message']) if is_sns_originated
      return message   
    end

    def calculate_latencies(record, body, message, is_sns_originated, current_time)
      latencies = {}

      recorded_at = message['recorded_at']
       
      sqs_sent_timestamp = record['attributes']['SentTimestamp'].to_i
      sqs_aprox_timestamp_rcv = record['attributes']['ApproximateFirstReceiveTimestamp'].to_i

      if is_sns_originated
        sns_timestamp = (Time.parse(body['Timestamp']).to_f*1000).to_i
        latencies[:producer_to_sns_latency] = sns_timestamp - recorded_at
        latencies[:sns_to_sqs_latency]= sqs_sent_timestamp - sns_timestamp
      else
        latencies[:producer_to_sqs_latency] = sqs_aprox_timestamp_rcv - recorded_at
      end

      latencies[:sqs_to_lambda_lacency] = sqs_aprox_timestamp_rcv - sqs_sent_timestamp
      latencies[:lambda_to_code_latency] = current_time - sqs_aprox_timestamp_rcv
      latencies[:latency] = current_time - recorded_at

      return latencies
    end

end