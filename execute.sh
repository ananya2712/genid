#!/bin/bash

rm -rf /tmp/genid_counter.lock

homebrew install flock
chmod +x genid.sh
chmod +x test_genid.sh

./genid.sh
./test_genid.sh