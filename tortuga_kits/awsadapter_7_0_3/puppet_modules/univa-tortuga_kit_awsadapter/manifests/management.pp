# Copyright 2008-2018 Univa Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


class tortuga_kit_awsadapter::management::package {
  require tortuga::packages

  include tortuga::config

  ensure_resource('package', 'unzip', {'ensure' => 'installed'})

  if $::osfamily == 'RedHat' {
    if versioncmp($facts['os']['release']['major'], '7') < 0 {
      # gcc is required only on RHEL/CentOS 6 to compile gevent
      ensure_packages(['gcc'], {'ensure' => 'installed'})

      exec { 'install_gevent_for_rhel_6':
        path    => ["${tortuga::config::instroot}/bin", '/bin', '/usr/bin'],
        command => "${tortuga::config::instroot}/bin/pip install 'gevent<1.2.0'",
        unless  => "${tortuga::config::instroot}/bin/pip freeze | grep -q gevent==",
        require => Package['gcc'],
      }
    }
  }
}

class tortuga_kit_awsadapter::management::post_install {
  include tortuga_kit_awsadapter::config

  require tortuga_kit_awsadapter::management::package

  tortuga::run_post_install { 'tortuga_kit_awsadapter_management_post_install':
    kitdescr  => $tortuga_kit_awsadapter::config::kitdescr,
    compdescr => $tortuga_kit_awsadapter::management::compdescr,
  }
  ~> Service['tortugawsd']
  ~> Service['celery']
}

class tortuga_kit_awsadapter::management {
  include tortuga_kit_awsadapter::config

  $compdescr = "management-${tortuga_kit_awsadapter::config::major_version}"

  contain tortuga_kit_awsadapter::management::package
  contain tortuga_kit_awsadapter::management::post_install

  Class['tortuga_kit_awsadapter::management::post_install'] ~>
    Class['tortuga_kit_base::installer::webservice::server']
}
