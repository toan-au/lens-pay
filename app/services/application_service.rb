class ApplicationService
  def self.call(...)
    new(...).call
  end

  def call
    result = perform
    AuditLogger.log(event: "#{event_name}", status: "succeeded", **log_context)
    result

  rescue => e
    AuditLogger.log(event: "#{event_name}", status: "failed", error: e, **log_context)
    raise
  end

  def perform
    raise NotImplementedError
  end

  def log_context
    {}
  end

  def event_name
    raise NotImplementedError
  end
end
