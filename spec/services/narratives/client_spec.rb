require "rails_helper"

RSpec.describe Narratives::Client do
  let(:endpoint) { "https://generativelanguage.googleapis.com/v1beta/models" }
  let(:model) { "gemini-2.5-flash" }
  let(:url) { "#{endpoint}/#{model}:generateContent" }

  def envelope(inner_text)
    { candidates: [ { content: { parts: [ { text: inner_text } ] } } ] }.to_json
  end

  def client(api_key: "test-key", model: "gemini-2.5-flash")
    described_class.new(api_key: api_key, model: model)
  end

  def generate(**overrides)
    client(**overrides.slice(:api_key, :model)).generate(
      system_instruction: overrides.fetch(:system_instruction, "You narrate payments."),
      user_content: overrides.fetch(:user_content, '{"amount":1000}'),
      schema: overrides.fetch(:schema, { "type" => "object" })
    )
  end

  it "posts the instruction, content and schema to the model's generateContent endpoint" do
    stub = stub_request(:post, url)
      .with(
        headers: { "x-goog-api-key" => "test-key", "Content-Type" => "application/json" },
        body: hash_including(
          "system_instruction" => { "parts" => [ { "text" => "You narrate payments." } ] },
          "contents" => [ { "role" => "user", "parts" => [ { "text" => '{"amount":1000}' } ] } ],
          "generationConfig" => hash_including(
            "responseMimeType" => "application/json",
            "responseSchema" => { "type" => "object" }
          )
        )
      )
      .to_return(status: 200, body: envelope('{"headline":"ok"}'))

    generate

    expect(stub).to have_been_requested
  end

  it "returns the parsed inner JSON from the first candidate" do
    stub_request(:post, url).to_return(status: 200, body: envelope('{"headline":"A quiet expiry","timeline":[]}'))

    expect(generate).to eq("headline" => "A quiet expiry", "timeline" => [])
  end

  it "uses the model from config in the request URL" do
    other = "#{endpoint}/gemini-flash-lite:generateContent"
    stub = stub_request(:post, other).to_return(status: 200, body: envelope('{"headline":"ok"}'))

    generate(model: "gemini-flash-lite")

    expect(stub).to have_been_requested
  end

  it "raises GenerationFailed on a non-2xx response" do
    stub_request(:post, url).to_return(status: 429, body: "rate limited")

    expect { generate }.to raise_error(NarrativeError::GenerationFailed)
  end

  it "raises GenerationFailed on a timeout" do
    stub_request(:post, url).to_timeout

    expect { generate }.to raise_error(NarrativeError::GenerationFailed)
  end

  it "raises GenerationFailed when the inner text is not valid JSON" do
    stub_request(:post, url).to_return(status: 200, body: envelope("not json at all"))

    expect { generate }.to raise_error(NarrativeError::GenerationFailed)
  end

  it "raises GenerationFailed when the response has no candidate text" do
    stub_request(:post, url).to_return(status: 200, body: { candidates: [] }.to_json)

    expect { generate }.to raise_error(NarrativeError::GenerationFailed)
  end

  it "raises NotConfigured and makes no request when the api key is blank" do
    stub = stub_request(:post, url)

    expect { generate(api_key: "") }.to raise_error(NarrativeError::NotConfigured)
    expect(stub).not_to have_been_requested
  end
end
