class AuditLogger
  def self.log(event:, status:, error: nil, **context)
    payload = {
      event: event,
      status: status,
      timestamp: Time.current.iso8601,
      **context
    }

    payload[:error_class] = error.class.name if error
    payload[:error_message] = error.message if error

    if error
      Rails.logger.error(payload.to_json)
    else
      Rails.logger.info(payload.to_json)
    end
  end
end
