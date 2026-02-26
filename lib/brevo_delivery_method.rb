require 'net/http'
require 'json'

class BrevoDeliveryMethod
  def initialize(settings)
    @api_key = settings[:api_key]
    @sender_email = settings[:sender_email]
  end

  def deliver!(mail)
    from_email = @sender_email.presence || Array(mail.from).first

    payload = {
      sender: { email: from_email },
      to: Array(mail.to).map { |e| { email: e } },
      subject: mail.subject
    }

    if mail.html_part
      payload[:htmlContent] = mail.html_part.body.decoded
    end

    if mail.text_part
      payload[:textContent] = mail.text_part.body.decoded
    end

    if payload[:htmlContent].nil? && payload[:textContent].nil?
      if mail.content_type.to_s.include?('text/html')
        payload[:htmlContent] = mail.body.decoded
      else
        payload[:textContent] = mail.body.decoded
      end
    end

    uri = URI('https://api.brevo.com/v3/smtp/email')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['api-key'] = @api_key
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request.body = payload.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Brevo delivery failed: #{response.code} #{response.body}"
    end
  end
end