require "net/http"

module Narratives
  # The one file that speaks Gemini. Takes a system instruction, user content
  # and a response schema; returns the model's structured JSON as a parsed Hash.
  # Swap providers here — nothing above this file knows about HTTP.
  class Client
    ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models".freeze
    TEMPERATURE = 0.7
    MAX_OUTPUT_TOKENS = 400

    def initialize(api_key: ENV["GEMINI_API_KEY"], model: ENV.fetch("NARRATIVE_MODEL", "gemini-2.5-flash"))
      @api_key = api_key
      @model = model
    end

    def generate(system_instruction:, user_content:, schema:)
      raise NarrativeError::NotConfigured if @api_key.blank?

      parse(post(request_body(system_instruction, user_content, schema)))
    end

    private

    def request_body(system_instruction, user_content, schema)
      {
        system_instruction: { parts: [ { text: system_instruction } ] },
        contents: [ { role: "user", parts: [ { text: user_content } ] } ],
        generationConfig: {
          temperature: TEMPERATURE,
          maxOutputTokens: MAX_OUTPUT_TOKENS,
          responseMimeType: "application/json",
          responseSchema: schema
        }
      }.to_json
    end

    def post(body)
      uri = URI("#{ENDPOINT}/#{@model}:generateContent")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 15

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["x-goog-api-key"] = @api_key
      request.body = body

      response = http.request(request)
      raise NarrativeError::GenerationFailed, "Gemini returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
      raise NarrativeError::GenerationFailed, e.message
    end

    def parse(response_body)
      text = JSON.parse(response_body).dig("candidates", 0, "content", "parts", 0, "text")
      raise NarrativeError::GenerationFailed, "empty response" if text.blank?

      JSON.parse(text)
    rescue JSON::ParserError => e
      raise NarrativeError::GenerationFailed, "unparseable response (#{e.message})"
    end
  end
end
