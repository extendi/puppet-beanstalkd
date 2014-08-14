class beanstalkd (
  $start_during_boot = 'false',
  $user = 'beanstalkd',
  $maxconn = '10000',
  $binlog = '/mnt/beanstalkd',
  $daemon_opts = '',
  $address = '127.0.0.1',
  $port = '11300'
) {

  package {'beanstalkd':
    ensure => present,
  }

  # create if not present beanstalkd folder
  file { 'create beanstalkd directory':
    path => $binlog,
    ensure => "directory",
    owner => $user,
    group => 'nogroup',
    mode => 'u=rwx,go=rx',
  }

  mount { '/mnt/beanstalkd':
    device => 'LABEL=beanstalkd',
    ensure => mounted,
    fstype => "ext4",
    atboot => true,
    options => 'defaults'
  }

  exec {'remove beanstalkd from rc.d':
    command => "/usr/sbin/update-rc.d -f beanstalkd remove",
    refreshonly => true
  }

  # hack to not create dependency cycle
  exec { 'remove beanstalkd config file':
    command => 'rm /etc/init.d/beanstalkd',
    path => "/bin",
    refreshonly => true,
    notify => Exec['remove beanstalkd from rc.d']
  }

  exec {'stop beanstalkd':
    command => "/etc/init.d/beanstalkd stop",
    path => "/root",
    onlyif => '/bin/ls /etc/init.d/beanstalkd',
    notify => Exec['remove beanstalkd config file']
  }

  file {'/etc/init/beanstalkd.conf':
    owner => 'root',
    group => 'root',
    mode => 'u=rw,go=r',
    content => template("${module_name}/beanstalkd.conf.erb"),
  }

  file {'/etc/default/beanstalkd':
    owner => 'root',
    group => 'root',
    mode => 'u=rw,go=r',
    content => template("${module_name}/beanstalkd.erb"),
  }

  service {'start beanstalkd':
    name => 'beanstalkd',
    ensure => running,
    provider => upstart
  }

  Package['beanstalkd'] -> File['create beanstalkd directory'] -> Mount['/mnt/beanstalkd'] -> Exec['stop beanstalkd'] -> File['/etc/init/beanstalkd.conf'] -> Service['start beanstalkd']
}