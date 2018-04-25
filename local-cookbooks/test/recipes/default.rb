secret = ::ChefCookbook::Secret::Helper.new(node)

file '/tmp/hello' do
  content "#{node.chef_environment}\n#{secret.get('test:secret', prefix_fqdn: false)}\n"
end
