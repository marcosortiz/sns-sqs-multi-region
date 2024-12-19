class SqsWorker

    def batch_process_records(records, max_retries=2, thread_count=5)
        t0 = Time.now
        failed_records = []
        failed_count = 0
        mutex = Mutex.new
      
        process_records = ->(recs) do
          threads = []
          recs.each_slice((recs.size.to_f / thread_count).ceil) do |slice|
            threads << Thread.new do
              slice.each do |record|
                success = process_record(record)
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
            process_rate: (records.length - failed_count) / elapsed_time
          },
          failed_records: failed_records
        }
    end
      

    private

    def process_record(record, retrying=false)
        begin
            body = JSON.parse(record['body'])
            message = JSON.parse(body['Message'])
            task_id = message['task_id']
            puts("#{task_id}")
            return true
        rescue StandardError => e
            puts("Error: #{e.message}")
            return false
        end
    end
end