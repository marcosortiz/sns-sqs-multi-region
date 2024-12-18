module Logger
    def self.log(message)
        puts "#{Time.now.strftime('%H:%M:%S.%L')} - #{message}"
    end
end