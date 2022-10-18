require_relative '../../app/helpers/auth'
include Auth

channel = RabbitMq.consumer_channel
exchange = channel.default_exchange
queue = channel.queue('authenticate', durable: true)

queue.subscribe(manual_ack: true) do |delivery_info, properties, payload|
  payload = JSON(payload)

  decodence = JwtEncoder.decode(payload['token'])
  result = Auth::FetchUserService.call(decodence['uuid'])
  
  if result.success?
    exchange.publish(
      result.user.id.to_s,
      routing_key: properties.reply_to,
      correlation_id: properties.correlation_id
    )    
  end


  channel.ack(delivery_info.delivery_tag)
end
