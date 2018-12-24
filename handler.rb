require 'json'
require 'aws-sdk-ecs'

def restart_service(event:, context:)
  event['Records'].each { |record| process_record(record) }
  { statusCode: 200, body: JSON.generate('OK') }
end

def process_record(record)
  record = Record.new(record)
  return unless record.valid

  ServiceRestarter.new(
    cluster_name: record.cluster_name,
    service_name: record.service_name
  ).run
end

class ServiceRestarter
  attr_reader :cluster_name, :service_name, :ecs_client

  def initialize(cluster_name:, service_name:, ecs_client: Aws::ECS::Client.new)
    @cluster_name = cluster_name
    @service_name = service_name
    @ecs_client = ecs_client
  end

  def run
    puts "Restarting #{cluster_name}:#{service_name}"
    ecs_client.update_service(
      cluster: cluster_name,
      service: service_name,
      force_new_deployment: true
    )
  end
end

class Record
  attr_reader :valid, :cluster_name, :service_name

  def initialize(payload)
    @payload = payload
    parse
  end

  private

  attr_reader :payload

  def parse
    @valid = false && return if payload.dig('Sns', 'Message').nil?
    begin
      message = JSON.parse(payload['Sns']['Message'])
      @cluster_name = get_dimension(message: message, name: 'ClusterName')
      @service_name = get_dimension(message: message, name: 'ServiceName')
      @valid = [@cluster_name, @service_name].all?
    rescue JSON::ParserError
      @valid = false
      return
    end
  end

  def get_dimension(message:, name:)
    dimensions = message.dig('Trigger', 'Dimensions')
    return nil unless dimensions

    dimensions.select { |d| d['name'] == name }.first['value']
  end
end
