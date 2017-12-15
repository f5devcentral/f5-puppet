require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_description.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_truthy.rb'))


Puppet::Type.newtype(:f5_profileserverssl) do
  @doc = 'Manage Server SSL profile objects'

  apply_to_device
  ensurable

  newparam(:name) do
    def self.postinit
      @doc ||= "The name of the object.
      Valid options: <String>"
    end

    validate do |value|
      fail ArgumentError, "#{name} must be a String" unless value.is_a?(String)
    end

    isnamevar

  end

  newproperty(:description, :parent => Puppet::Property::F5Description)

# newproperty(:cert, :required_features => :cert,  :parent => Puppet::Property::F5Profile) do
#  end
 newproperty(:cert) do
    desc "cert"
  end

 newproperty(:key) do
    desc "key"
  end

  newproperty(:proxy_ssl, :parent => Puppet::Property::F5truthy) do
    desc "Valid values are 'enabled' or 'disabled'."
    truthy_property('Fail Safe')
  end

  newproperty(:proxy_ssl_passthrough, :parent => Puppet::Property::F5truthy) do
    desc "Valid values are 'enabled' or 'disabled'."
    truthy_property('Fail Safe')
  end

  newproperty(:ssl_forward_proxy, :parent => Puppet::Property::F5truthy) do
    desc "Valid values are 'enabled' or 'disabled'."
    truthy_property('Fail Safe')
  end

  newproperty(:ssl_forward_proxy_bypass, :parent => Puppet::Property::F5truthy) do
    desc "Valid values are 'enabled' or 'disabled'."
    truthy_property('Fail Safe')
  end

  newproperty(:peer_cert_mode) do
    desc "peer_cert_mode."
    newvalues(:ignore, :'require')
  end

  newproperty(:expire_cert_response_control) do
    desc "expire_cert_response_control."
    newvalues(:'drop', :'ignore')
  end

  newproperty(:untrusted_cert_response_control) do
    desc "untrusted_cert_response_control."
    newvalues(:'drop', :'ignore')
  end

  newproperty(:authenticate) do
    desc "authenticate."
    newvalues(:'once', :'always')
  end

  newproperty(:retain_certificate, :parent => Puppet::Property::F5truthy) do
    desc "Valid values are 'enabled' or 'disabled'."
    truthy_property('Fail Safe')
  end

  newproperty(:authenticate_depth) do
    desc "authenticate_depth."
  end

end
