secret = ::ChefCookbook::Secret::Helper.new(node)

file '/tmp/hello' do
  content "#{node.chef_environment}\n#{secret.get('test:secret', prefix_fqdn: false)}\n"
end

log 'message' do
  level :info
  message node['test']['message']
end
