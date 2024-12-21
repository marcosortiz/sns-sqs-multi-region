require 'time'

class SqsWorker

    def batch_process_records(records, max_retries=2, thread_count=5)
        t0 = Time.now
        failed_records = []
        sns_to_sqs_latencies = []
        sqs_to_lambda_lacencies = []
        latencies = []
        failed_count = 0
        mutex = Mutex.new
      
        process_records = ->(recs) do
          threads = []
          recs.each_slice((recs.size.to_f / thread_count).ceil) do |slice|
            threads << Thread.new do
              now = Time.now.to_f*1000
              slice.each do |record|
                body = JSON.parse(record['body'])
                message = JSON.parse(body['Message'])
                task_id = message['task_id']

                # Putting all timestamps in milliseconds
                sns_timestamp = Time.parse(body['Timestamp']).to_f*1000
                recorded_at = Time.parse(message['recorded_at']).to_f*1000
                sent_timestamp = record['attributes']['SentTimestamp'].to_i
                aprox_timestamp_rcv = record['attributes']['ApproximateFirstReceiveTimestamp'].to_i
                sns_to_sqs_latency = aprox_timestamp_rcv - sent_timestamp
                sqs_to_lambda_lacency = now - aprox_timestamp_rcv
                latency = now - recorded_at
                
                mutex.synchronize do
                  sns_to_sqs_latencies << sns_to_sqs_latency
                  sqs_to_lambda_lacencies << sqs_to_lambda_lacency
                  latencies << latency
                end
                
                success = process_record(task_id)
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
        {
          report: {
            batch_size: records.length,
            success_count: records.length - failed_count,
            failed_count: failed_count,
            retries: [max_retries, failed_records.empty? ? max_retries : max_retries - 1].min,
            duration: elapsed_time,
            process_rate: (records.length - failed_count) / elapsed_time,
            sns_to_sqs_latency: sns_to_sqs_latencies.max,
            sqs_to_lambda_lacency: sqs_to_lambda_lacencies.max,
            latency: latencies.max
          },
          failed_records: failed_records
        }
    end
      

    private

    def process_record(task_id, retrying=false)
        begin
            puts("#{task_id}")
            return true
        rescue StandardError => e
            puts("Error: #{e.message}")
            return false
        end
    end
end