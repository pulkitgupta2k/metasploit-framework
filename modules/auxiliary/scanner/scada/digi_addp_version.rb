##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'rex/proto/addp'

class MetasploitModule < Msf::Auxiliary
  include Msf::Auxiliary::Report
  include Msf::Auxiliary::UDPScanner

  def initialize
    super(
      'Name'        => 'Digi ADDP Information Discovery',
      'Description' => 'Discover host information through the Digi International ADDP service',
      'Author'      => 'hdm',
      'References'  =>
        [
          ['URL', 'http://qbeukes.blogspot.com/2009/11/advanced-digi-discovery-protocol_21.html'],
          ['URL', 'http://www.digi.com/wiki/developer/index.php/Advanced_Device_Discovery_Protocol_%28ADDP%29'],
        ],
      'License'     => MSF_LICENSE
    )

    register_options(
    [
      Opt::RPORT(2362),
      OptString.new('ADDP_PASSWORD', [true, 'The ADDP protocol password for each target', 'dbps'])
    ])
  end

  def scanner_prescan(batch)
    print_status("Finding ADDP nodes within #{batch[0]}->#{batch[-1]} (#{batch.length} hosts)")
    @results = {}
  end

  def scan_host(ip)
    Rex::Proto::ADDP.request_config_all.each do |pkt|
      scanner_send(pkt, ip, datastore['RPORT'])
    end
  end

  def scanner_process(data, shost, sport)
    res = Rex::Proto::ADDP.decode_reply(data)
    return unless res[:magic] and res[:mac]
    res[:banner] = Rex::Proto::ADDP.reply_to_string( res )

    unless @results[shost]
      print_good("#{shost}:#{datastore['RPORT']} ADDP #{res[:banner]}")
      report_service(
        :host  => shost,
        :mac   => res[:mac],
        :port  => datastore['RPORT'],
        :proto => 'udp',
        :name  => 'addp',
        :info  => res[:banner]
      )
    end

    @results[shost] = res
  end


end
