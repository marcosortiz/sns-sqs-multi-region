require 'json'
require_relative 'util/sqs-worker'
require_relative 'util/emf'


WORKER = SqsWorker.new()
EMF = EmfLogger.new('SnsSqsMultiRegion', 'SqsConsumer')

def handler(event:, context:)
  records = event['Records']
  puts "Processing #{records.length} records"
  resp = WORKER.batch_process_records(records, 3, 5)
  puts resp[:report]
  EMF.log_metrics(resp[:report])

    # Collect failed records
  failed_records = resp[:failed_records] || []
  puts "Failed to process #{failed_records.length} records" if failed_records.length > 0

  # Return partial failures
  sqs_batch_response = {
    'batchItemFailures' => failed_records.map { |record| { 'itemIdentifier' => record['messageId'] } }
  }
end