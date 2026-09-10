Gem::Specification.new do |spec|
  spec.name          = "rubycopier"
  spec.version       = "1.0.0"
  spec.authors       = ["MetaRPC"]
  spec.email         = ["support@mrpc.pro"]
  spec.summary       = "Official Ruby SDK for MetaRPC Trade Copier via gRPC"
  spec.license       = "MIT"
  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
  spec.add_dependency "grpc", "~> 1.60"
end
