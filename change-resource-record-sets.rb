require 'socket'

current_ip = Socket.ip_address_list[4].ip_address
last_ip_path = File.expand_path File.dirname(__FILE__), 'last_ip'

unless File.exist?(last_ip_path) and current_ip == File.read(last_ip_path)
  File.write last_ip_path, current_ip
  config_file_path =
    File.expand_path File.dirname(__FILE__), 'config.yml'
  json_file_path =
    File.expand_path File.dirname(__FILE__), 'change-resource-record-sets.json'

  require 'yaml'
  config = YAML.load_file config_file_path

  json =  "{\n" +
          "    \"Comment\": \"Update record\",\n" +
          "    \"Changes\": [\n" +
          "        {\n" +
          "            \"Action\": \"UPSERT\",\n" +
          "            \"ResourceRecordSet\": {\n" +
          "                \"Name\": \"#{config['name']}\",\n" +
          "                \"Type\": \"#{config['type']}\",\n" +
          "                \"TTL\": #{config['ttl']},\n" +
          "                \"ResourceRecords\": [\n" +
          "                    {\n" +
          "                        \"Value\": \"#{current_ip}\"\n" +
          "                    }\n" +
          "                ]\n" +
          "            }\n" +
          "        }\n" +
          "    ]\n" +
          "}\n"

  File.write json_file_path, json

  cmd = "aws route53 change-resource-record-sets " +
        "--hosted-zone-id #{config['hosted_zone_id']} " +
        "--change-batch file://#{json_file_path} > /dev/null 2>&1"

  system cmd
end
