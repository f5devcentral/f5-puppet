Puppet::Type.newtype(:f5_node) do
  @doc = 'Manage node objects'

  apply_to_device
  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the node object.'
  end
end
