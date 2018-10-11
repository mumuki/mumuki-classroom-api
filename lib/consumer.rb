class Mumukit::Nuntius::Consumer
  def negligent_start!(queue_name, &block)
    start queue_name, queue_name do |_delivery_info, _properties, body|
      begin
        block.call(body)
      rescue => e
        Mumuki::Classroom::Nuntius.logger.error "#{queue_name} item couldn't be processed #{e}. body was: #{body}"
      end
    end
  end
end

