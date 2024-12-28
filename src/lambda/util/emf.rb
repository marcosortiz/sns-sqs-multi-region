
require 'json'

class EmfLogger

    METRICS_HASH = {
        batch_size: {name: 'BatchSize', unit: 'Count'},
        success_count: {name:'SuccessCount', unit: 'Count'},
        failed_count: {name: 'FailedCount', unit: 'Count'},
        retries: {name: 'Retries', unit: 'Count'},
        duration: {name: 'Duration', unit: 'Seconds'},
        process_rate: {name: 'ProcessingRate', unit: 'Count/Second'},
        producer_to_sns_latency: {name: 'ProducerToSnsLatency', unit: 'Milliseconds'},
        sns_to_sqs_latency: {name: 'SnsToSqsLatency', unit: 'Milliseconds'},
        sqs_to_lambda_lacency: {name: 'SqsToLambdaLatency', unit: 'Milliseconds'},
        lambda_to_code_latency: {name: 'LambdaToCodeLatency', unit: 'Milliseconds'},
        latency: {name: 'Latency', unit: 'Milliseconds'}
    }


    def initialize(namespace, service_name)
        @namespace = namespace 
        @service_name = service_name
    end

    def log_metrics(report)
        metrics = []
        report.each do |key, value|
            hash = {
                "Name": METRICS_HASH[key][:name],
                "Unit": METRICS_HASH[key][:unit],
                "StorageResolution": 1
            }
            metrics << hash
        end      

        # Create an EMF log event
        emf_log = {
            "_aws": {
                "Timestamp": Time.now.to_i * 1000,
                "CloudWatchMetrics": [
                    {
                        "Namespace": @namespace,
                        "Dimensions": [["ServiceName"]],
                        "Metrics": metrics
                    }
                ]
            },
            "ServiceName": @service_name
        }


        # Add metric values
        report.each do |key, value|
            emf_log[METRICS_HASH[key][:name]] = value
        end

        puts JSON.generate(emf_log)
    end

end

