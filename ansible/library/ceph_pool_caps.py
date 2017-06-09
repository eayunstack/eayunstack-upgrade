#!/usr/bin/env python

# Copyright 2016 Eayun, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DOCUMENTATION = '''
---
module: ceph_osd_caps
short_description: Module for updating Ceph CephX caps for osd pools
description:
     - A module targeting at updating Ceph CephX caps for osd pools used by EayunStack Ansible.
options:
  user:
    description:
      - The use whose caps will be modified
    required: True
    type: str
  pool:
    description:
      - The pool of which the user's caps rely on
    required: True
    type: str
  caps:
    description:
      - The caps of the user on the pool ( '*' is also valid )
    required: True
    type: str
    choices:
      - r
      - w
      - x
      - rw
      - rx
      - wx
      - rwx
'''

EXAMPLES = '''
- hosts: controller[0]
  tasks:
    - name: Ensure client.volumes can read/write/execute on pool images
      ceph_pool_caps:
        user: client.volumes
        pool: images
        caps: rwx
'''

from itertools import chain, combinations
import subprocess
import json


RWX = ['r', 'w', 'x']
VALID_CAPS = ['*'] + [
    ''.join(c) for c in chain.from_iterable(
        combinations(RWX, r)
        for r in range(1, len(RWX)+1)
        )
    ]
CEPH_CMD_PREFIX = ['ceph', '--format=json', 'auth']


class CephUserPoolCaps(object):

    def __init__(self, user_auth):
        self.entity = user_auth.get('entity')
        self.key = user_auth.get('key')
        self.caps = {}
        self.changed = False

        self.parse_caps(user_auth.get('caps'))

    @classmethod
    def find(cls, entity):
        command = CEPH_CMD_PREFIX + ['get', entity]
        p = subprocess.Popen(command,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        out, _ = p.communicate()

        if not p.returncode:
            user_auth = json.loads(out)[0]
            return cls(user_auth)
        else:
            return None

    @classmethod
    def create(cls, user, pool, cap):
        command = CEPH_CMD_PREFIX + ['add', user]
        user_auth = {
            'entity': user,
            'caps': {
                'osd': 'allow %s pool=%s' % (cap, pool)}}
        temp_obj = cls(user_auth)
        command += temp_obj.build_cmd_args()
        del temp_obj
        p = subprocess.Popen(command,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        p.communicate()

        if not p.returncode:
            new_obj = cls.find(user)
            new_obj.changed = True
            return new_obj
        else:
            raise

    def update(self, pool, caps):
        pool = pool.decode('utf-8')
        caps = caps.decode('utf-8')

        command = CEPH_CMD_PREFIX + ['caps', self.entity]

        found = False
        for pool_caps in self.caps['osd']['pools']:
            if pool_caps['pool'] == pool:
                found = True
                if pool_caps['acl'] != caps:
                    pool_caps['acl'] = caps
                    self.changed = True

        if not found:
            self.caps['osd']['pools'].append({'pool': pool,
                                              'acl': caps})
            self.changed = True

        if self.changed:
            command += self.build_cmd_args()
            p = subprocess.Popen(command,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            p.communicate()

            if p.returncode:
                raise

    def to_dict(self):
        return {
            'entity': self.entity,
            'key': self.key,
            'caps': self.caps
            }

    def parse_caps(self, user_caps):
        for cap_type, caps in user_caps.iteritems():
            if cap_type == 'osd':
                self.caps['osd'] = {}
                self.parse_osd_caps(caps)
            else:
                self.caps[cap_type] = caps

    def parse_osd_caps(self, osd_caps):
        self.caps['osd']['pools'] = []
        for cap in osd_caps.split(','):
            cap_split = cap.strip().split()
            if (len(cap_split) == 3 and
                    cap_split[2].startswith('pool=')):
                pool = cap_split[2].strip('pool=')
                acl = cap_split[1]
                self.caps['osd']['pools'].append({'pool': pool,
                                                  'acl': acl})
            else:
                self.caps['osd']['common'] = cap

    def build_cmd_args(self):
        cmd_args = []
        for cap_type, caps in self.caps.iteritems():
            cmd_args.append(cap_type)

            if cap_type == 'osd':
                caps_args = self.build_pool_args(caps)
            else:
                caps_args = caps

            cmd_args.append(caps_args)

        return cmd_args

    def build_pool_args(self, osd_pool_caps):
        osd_pool_args = []
        common_caps = osd_pool_caps.get('common')
        if common_caps:
            osd_pool_args.append(common_caps)

        for cap in osd_pool_caps['pools']:
            osd_pool_args.append('allow %s pool=%s' % (cap['acl'],
                                                       cap['pool']))

        return ','.join(osd_pool_args)


def generate_module():
    argument_spec = dict(
        user=dict(required=True, type='str'),
        pool=dict(required=True, type='str'),
        caps=dict(required=True, type='str', choices=VALID_CAPS)
    )
    module = AnsibleModule(
        argument_spec=argument_spec,
    )

    return module


def main():
    module = generate_module()

    user_pool_caps = CephUserPoolCaps.find(
        module.params.get('user')
    )

    failed = False
    if not user_pool_caps:
        try:
            user_pool_caps = CephUserPoolCaps.create(
                module.params.get('user'),
                module.params.get('pool'),
                module.params.get('caps')
            )
        except Exception:
            failed = True
            failed_msg = 'Creating user failed'
    else:
        try:
            user_pool_caps.update(
                module.params.get('pool'),
                module.params.get('caps')
            )
        except Exception:
            failed = True
            failed_msg = 'Updating user failed'

    if not failed:
        module.exit_json(changed=user_pool_caps.changed,
                         result=user_pool_caps.to_dict())
    else:
        module.exit_json(failed=True,
                         msg=failed_msg)


from ansible.module_utils.basic import *
if __name__ == '__main__':
    main()
