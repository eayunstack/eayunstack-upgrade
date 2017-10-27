#!/usr/bin/python
# -*- coding: utf-8 -*-
# (c) 2014, Kevin Carter <kevin.carter@rackspace.com>
#
# Copyright 2014, Rackspace US, Inc.
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

# Based on Jimmy Tang's implementation

DOCUMENTATION = """
---
module: keystone_v2_endpoint
short_description:
    - Manage OpenStack Identity (keystone) v2 endpoint.
description:
    - Manage OpenStack Identity (keystone) v2 endpoint.
      endpoints.
options:
    token:
        description:
            - The token to be uses in case the password is not specified
        required: true
        default: None
    endpoint:
        description:
            - The keystone url for authentication
        required: true
    service_name:
        description:
            - Name of the service.
        required: true
        default: None
    region_name:
        description:
            - Name of the region.
        required: true
        default: None
    service_type:
        description:
            - Type of service.
        required: true
        default: None
    endpoint_dict:
        description:
            - Dict of endpoint urls to add to keystone for a service
        required: true
        default: None
        type: dict
    state:
        description:
            - Ensuring the endpoint is either present, absent.
            - It always ensures endpoint is updated to latest url.
        required: False
        default: 'present'

requirements: [ python-keystoneclient ]
"""

EXAMPLES = """
# Create an endpoint
- keystone_v2_endpoint:
    region_name: "RegionOne"
    service_name: "glance"
    service_type: "image"
    endpoint: "http://127.0.0.1:5000/v2.0/"
    token: "ChangeMe"
    endpoint_dict:
      publicurl: "http://127.0.0.1:9292"
      adminurl: "http://127.0.0.1:9292"
      internalurl: "http://127.0.0.1:9292"

"""

try:
    from keystoneclient.v2_0 import client
except ImportError:
    keystoneclient_found = False
else:
    keystoneclient_found = True


class ManageKeystoneV2Endpoint(object):
    def __init__(self, module):
        """Manage Keystone via Ansible."""
        self.state_change = False
        self.keystone = None

        # Load AnsibleModule
        self.module = module

    @staticmethod
    def _facts(facts):
        """Return a dict for our Ansible facts.

        :param facts: ``dict``  Dict with data to return
        """
        return {'keystone_facts': facts}

    def failure(self, error, rc, msg):
        """Return a Failure when running an Ansible command.

        :param error: ``str``  Error that occurred.
        :param rc: ``int``     Return code while executing an Ansible command.
        :param msg: ``str``    Message to report.
        """
        self.module.fail_json(msg=msg, rc=rc, err=error)

    def _authenticate(self):
        """Return a keystone client object."""
        endpoint = self.module.params.get('endpoint')
        token = self.module.params.get('token')

        if token is None:
            self.failure(
                error='Missing Auth Token',
                rc=2,
                msg='Auto token is required!'
            )

        if token:
            self.keystone = client.Client(
                endpoint=endpoint,
                token=token
            )

    def _get_service(self, name, srv_type=None):
        for entry in self.keystone.services.list():
            if srv_type is not None:
                if entry.type == srv_type and name == entry.name:
                    return entry
            elif entry.name == name:
                return entry
        else:
            return None

    def _get_endpoint(self, region, service_id):
        """ Getting endpoints per complete definition

        Returns the endpoint details for an endpoint matching
        region, service id.

        :param service_id: service to which the endpoint belongs
        :param region: geographic location of the endpoint

        """
        for entry in self.keystone.endpoints.list():
            check = [
                entry.region == region,
                entry.service_id == service_id,
            ]
            if all(check):
                return entry
        else:
            return None

    def _compare_endpoint_info(self, endpoint, endpoint_dict):
        """ Compare existed endpoint with module parameters

        Return True if public, admin, internal urls are all the same.

        :param endpoint: endpoint existed
        :param endpoint_dict: endpoint info passed in

        """

        check = [
            endpoint.adminurl == endpoint_dict.get('adminurl'),
            endpoint.publicurl == endpoint_dict.get('publicurl'),
            endpoint.internalurl == endpoint_dict.get('internalurl')
        ]

        if all(check):
            return True
        else:
            return False

    def ensure_endpoint(self):
        """Ensures the deletion/modification/addition of endpoints
        within Keystone.

        Returns the endpoint ID on a successful run.

        """
        self._authenticate()

        service_name = self.module.params.get('service_name')
        service_type = self.module.params.get('service_type')
        region = self.module.params.get('region_name')
        endpoint_dict = self.module.params.get('endpoint_dict')
        state = self.module.params.get('state')

        endpoint_dict = {
            'adminurl': endpoint_dict.get('adminurl', ''),
            'publicurl': endpoint_dict.get('publicurl', ''),
            'internalurl': endpoint_dict.get('internalurl', '')
        }

        service = self._get_service(name=service_name, srv_type=service_type)
        if service is None:
            self.failure(
                error='service [ %s ] was not found.' % service_name,
                rc=2,
                msg='Service was not found, does it exist?'
            )

        existed_endpoint = self._get_endpoint(
            region=region,
            service_id=service.id,
        )

        delete_existed = False

        if state == 'present':
            ''' Creating an endpoint (if it does
                not exist) or creating a new one,
                and then deleting the existing
                endpoint that matches the service
                type, name, and region.
            '''
            if existed_endpoint:
                if not self._compare_endpoint_info(existed_endpoint,
                                                   endpoint_dict):
                    delete_existed = True
                else:
                    endpoint = existed_endpoint

            if (not existed_endpoint or
                    delete_existed):
                self.state_change = True
                endpoint = self.keystone.endpoints.create(
                    region=region,
                    service_id=service.id,
                    **endpoint_dict
                )

        elif state == 'absent':
            if existed_endpoint is not None:
                self.state_change = True
                delete_existed = True

        if delete_existed:
            result = self.keystone.endpoints.delete(existed_endpoint.id)
            if result[0].status_code != 204:
                self.module.fail()

        if state != 'absent':
            facts = self._facts(endpoint.to_dict())
        else:
            facts = self._facts({})

        self.module.exit_json(
            changed=self.state_change,
            ansible_facts=facts
        )

# TODO(evrardjp): Deprecate state=update in Q.
def main():
    module = AnsibleModule(
        argument_spec=dict(
            token=dict(
                required=True
            ),
            endpoint=dict(
                required=True,
            ),
            region_name=dict(
                required=True
            ),
            service_name=dict(
                required=True
            ),
            service_type=dict(
                required=True
            ),
            endpoint_dict=dict(
                required=True,
                type='dict'
            ),
            state=dict(
                choices=['present', 'absent'],
                required=False,
                default='present'
            )
        ),
        supports_check_mode=False,
    )

    km = ManageKeystoneV2Endpoint(module=module)
    if not keystoneclient_found:
        km.failure(
            error='python-keystoneclient is missing',
            rc=2,
            msg='keystone client was not importable, is it installed?'
        )

    facts = km.ensure_endpoint()


# import module snippets
from ansible.module_utils.basic import *  # NOQA
if __name__ == '__main__':
    main()
