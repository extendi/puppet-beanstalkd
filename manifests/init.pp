class beanstalkd (
  $start_during_boot = 'false',
  $user = 'beanstalkd',
  $maxconn = '10000',
  $binlog = '/mnt/beanstalkd',
  $daemon_opts = ''
) {

  package {'beanstalkd':
    ensure => present,
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

  Package['beanstalkd'] -> Exec['stop beanstalkd'] -> File['/etc/init/beanstalkd.conf'] -> Service['start beanstalkd']
}