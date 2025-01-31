require "rails_helper"

RSpec.describe Kubernetes::Client do
  describe "#new" do
    it "initialises a client with defaults" do
      allow(File).to receive(:exist?).once.with(Kubernetes::Client::CA_FILE).and_return(false)

      expect(Kubeclient::Client).to receive(:new).once.with(
        Kubernetes::Client::API_SERVER,
        Kubernetes::Client::API_VERSION,
        auth_options: { bearer_token_file: Kubernetes::Client::BEARER_TOKEN_FILE },
        ssl_options: {},
      )

      described_class.new
    end

    it "initialises a client with CA file if exists" do
      allow(File).to receive(:exist?).with(Kubernetes::Client::CA_FILE).and_return(true)

      expect(Kubeclient::Client).to receive(:new).once.with(
        Kubernetes::Client::API_SERVER,
        Kubernetes::Client::API_VERSION,
        auth_options: { bearer_token_file: Kubernetes::Client::BEARER_TOKEN_FILE },
        ssl_options: { ca_file: Kubernetes::Client::CA_FILE },
      )

      described_class.new
    end
  end

  describe "#namespace" do
    it "returns the namespace stored filepath" do
      allow(Kubeclient::Client).to receive(:new)

      allow(File).to receive(:read).with(Kubernetes::Client::NAMESPACE_FILE)
        .and_return("apps")

      client = described_class.new

      expect(client.namespace).to eql "apps"
    end
  end

  describe "#get_config_map" do
    it "calls get config map from kubernetes API" do
      kubeclient = double
      allow(Kubeclient::Client).to receive(:new).and_return(kubeclient)
      allow(File).to receive(:read).with(Kubernetes::Client::NAMESPACE_FILE)
        .and_return("apps")

      expect(kubeclient).to receive(:get_config_map).once.with(
        "configmap_name",
        "apps",
      )

      client = described_class.new
      client.get_config_map("configmap_name")
    end
  end

  describe "#apply_secret" do
    it "calls apply secret from kubernetes API" do
      kubeclient = double
      allow(Kubeclient::Client).to receive(:new).and_return(kubeclient)
      allow(File).to receive(:read).with(Kubernetes::Client::NAMESPACE_FILE)
        .and_return("apps")

      config = {
        apiVersion: Kubernetes::Client::API_VERSION,
        kind: "Secret",
        metadata: {
          name: "name",
          namespace: "apps",
        },
        type: "Opaque",
        data: { "key" => "dmFsdWU=\n" },
      }
      resource = Kubeclient::Resource.new(config)
      allow(Kubeclient::Resource).to receive(:new).and_return(resource)

      expect(kubeclient).to receive(:apply_secret).once.with(
        resource,
        field_manager: "signon",
      )

      client = described_class.new
      client.apply_secret("name", { "key" => "value" })
    end
  end
end
