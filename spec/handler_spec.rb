require_relative '../handler.rb'
require 'spec_helper'

describe Record do
  let(:correct_payload) do
    JSON.parse(
      File.read(
        File.join(File.dirname(__FILE__), 'correct_payload.json')
      )
    )
  end
  let(:incorrect_payload) do
    JSON.parse(
      File.read(
        File.join(File.dirname(__FILE__), 'incorrect_payload.json')
      )
    )
  end
  let(:cluster_name) { 'staging-railsapp' }
  let(:service_name) { 'api' }

  subject { described_class.new(payload['Records'].first) }

  context 'for a valid payload' do
    let(:payload) { correct_payload }
    it 'gives the correct information' do
      expect(subject.valid).to eq(true)
      expect(subject.cluster_name).to eq(cluster_name)
      expect(subject.service_name).to eq(service_name)
    end
  end

  context 'for an invalid payload' do
    let(:payload) { incorrect_payload }
    it 'gives the correct information' do
      expect(subject.valid).to eq(false)
      expect(subject.cluster_name).to eq(nil)
      expect(subject.service_name).to eq(nil)
    end
  end
end

describe ServiceRestarter do
  let(:cluster_name) { 'staging-railsapp' }
  let(:service_name) { 'api' }
  let(:ecs_client) { double(:ecs_client) }

  subject do
    described_class.new(cluster_name: cluster_name,
                        service_name: service_name,
                        ecs_client: ecs_client)
  end

  it 'makes a request to restart the fargate service' do
    expect(ecs_client).to receive(:update_service).with(
      cluster: cluster_name,
      service: service_name,
      force_new_deployment: true
    )
    subject.run
  end
end

describe 'Handler' do
  let(:correct_payload) do
    JSON.parse(
      File.read(
        File.join(File.dirname(__FILE__), 'correct_payload.json')
      )
    )
  end
  let(:incorrect_payload) do
    JSON.parse(
      File.read(
        File.join(File.dirname(__FILE__), 'incorrect_payload.json')
      )
    )
  end
  let(:cluster_name) { 'staging-railsapp' }
  let(:service_name) { 'api' }

  context 'with the correct payload' do
    let(:payload) { correct_payload }

    it 'restarts the service' do
      restarter_double_instance = instance_double('ServiceRestarter')
      expect(ServiceRestarter).to receive(:new).with(
        cluster_name: cluster_name,
        service_name: service_name
      ).and_return(restarter_double_instance)
      expect(restarter_double_instance).to receive(:run)
      response = restart_service(event: payload, context: {})
      expect(response).to eq(statusCode: 200, body: JSON.generate('OK'))
    end
  end

  context 'with an incorrect payload' do
    let(:payload) { incorrect_payload }

    it 'restarts the service' do
      restarter_double_instance = instance_double('ServiceRestarter')
      expect(ServiceRestarter).not_to receive(:new).with(
        cluster_name: cluster_name,
        service_name: service_name
      )
      response = restart_service(event: payload, context: {})
      expect(response).to eq(statusCode: 200, body: JSON.generate('OK'))
    end
  end
end
