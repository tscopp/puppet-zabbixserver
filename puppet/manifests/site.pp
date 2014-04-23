node zabbix{
  class { 'zabbixserver': }
  notice('initializing zabbixserver...')
}
