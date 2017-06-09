#!/usr/bin/env python

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

import os
import shutil
import random
import string
import sys
import yaml
import json

SRC_PATH = '/var/www/nailgun/eayunstack/ansible/passwords.yml'
DEST_PATH = '/etc/eayunstack/docker/passwords.yml'


def main():
    # length of password
    length = 40

    dest_dir = os.path.dirname(DEST_PATH)
    if not os.path.exists(DEST_PATH):
        if not os.path.exists(dest_dir):
            try:
                os.makedirs(dest_dir)
            except OSError:
                print('Creating %s failed!' % dest_dir)
                sys.exit(1)
        else:
            if not os.path.isdir(dest_dir):
                print('%s is not a directory!' % dest_dir)
                sys.exit(1)

        shutil.copyfile(SRC_PATH, DEST_PATH)
    else:
        if not os.path.isfile(DEST_PATH):
            print('%s is not a regular file!' % DEST_PATH)
            sys.exit(1)
    
    with open(SRC_PATH, 'r') as f:
        passwords = yaml.safe_load(f.read())

    with open(DEST_PATH, 'r') as f:
        dest_passwords = yaml.safe_load(f.read())

    passwords.update(dest_passwords)
    for k, v in passwords.items():
        if v is None:
            passwords[k] = ''.join([
                random.SystemRandom().choice(
                    string.ascii_letters + string.digits)
                for n in range(length)
            ])

    need_update = False
    for k, v in passwords.items():
        if (k in dest_passwords.keys() and
                v == dest_passwords[k]):
            continue
        else:
            need_update = True

    if need_update:
        with open(DEST_PATH, 'w') as f:
            f.write(yaml.safe_dump(passwords, default_flow_style=False))

    print json.dumps({'updated': need_update}, indent=2)


if __name__ == '__main__':
    main()
