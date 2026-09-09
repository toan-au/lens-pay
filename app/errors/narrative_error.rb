module NarrativeError
  class NotConfigured < StandardError
    def initialize = super("Narrative generation is not configured")
  end

  class GenerationFailed < StandardError
    def initialize(reason)
      super("Narrative generation failed: #{reason}")
    end
  end
end
