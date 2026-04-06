class ApplicationController < ActionController::API
    rescue_from ActionController::ParameterMissing do |e|
        render json: { error: "Missing parameter: #{e.param}" }, status: :bad_request
    end
end
