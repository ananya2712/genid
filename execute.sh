#!/bin/bash

rm -rf /tmp/genid_counter.lock

chmod +x genid.sh
chmod +x test_genid.sh

./genid.sh
./test_genid.sh