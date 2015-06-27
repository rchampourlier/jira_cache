# Saves and loads response to be used as fixtures for HTTP request
# responses.
class ResponseFixture

  def self.create(identifier, payload)
    File.write(file(identifier), payload.to_json)
  end

  def self.get(identifier)
    File.read(file(identifier))
  end

  def self.file(identifier)
    File.expand_path("../../fixtures/responses/#{identifier}.json", __FILE__)
  end
end
