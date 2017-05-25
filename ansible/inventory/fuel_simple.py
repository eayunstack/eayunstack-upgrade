#!/usr/bin/env python

import argparse
import json
from collections import defaultdict
from fuelclient.client import APIClient

NODES_URL = "/nodes"
FACTS_URL = "/clusters/%s/orchestrator/deployment/defaults/?nodes=%s"


def fuel_inventory():
    inventory = defaultdict(list)
    inventory['_meta'] = {
        'hostvars': {},
    }

    nodes = APIClient.get_request(NODES_URL)
    ready_nodes = [node for node in nodes if
                   (node['status'] == 'ready' and
                    node['online'])]

    for node in ready_nodes:
        node_fqdn = node['fqdn']
        node_cluster = node['cluster']
        node_roles = node['roles']

        inventory['cluster-%d' % node_cluster].append(node_fqdn)

        for role in node_roles:
            inventory[role].append(node_fqdn)

    return inventory


def json_format_dict(data):
    """ Converts a dict to a JSON object and dumps it as a formatted string """

    return json.dumps(data, sort_keys=True, indent=2)


if __name__ == '__main__':
    argparser = argparse.ArgumentParser(
        description='Produce an Ansible Inventory file based on Fuel')
    argparser.add_argument('--list', action='store_true',
                           default=True,
                           help='List all nodes (default: True)')
    argparser.add_argument('--host', action='store',
                           help='Get all the variables about a specific node')

    args = argparser.parse_args()
    inventory = fuel_inventory()

    if args.host:
        print json_format_dict(inventory['_meta']['hostvars'].get(args.host))
    else:
        print json_format_dict(inventory)
