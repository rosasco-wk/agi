// Copyright (C) 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package ffx_test

import (
	"errors"
	"testing"

	"github.com/google/gapid/core/log"
	"github.com/google/gapid/core/os/fuchsia/ffx"
)

func TestParseDevices(t_ *testing.T) {
	ctx := log.Testing(t_)

	// Concatenate IP addresses and device names together as a facsimile of the real stdout from ffx
	// with 3 available devices.
	const NUM_DEVICES = 3
	ipAddrs := [NUM_DEVICES]string{"fe80::5054:ff:fe63:5e7a%1", "fe80::5054:ff:fe63:5e7a%1", "fe80::5054:ff:fe63:5e7a%1"}
	deviceNames := [NUM_DEVICES]string{"fuchsia-5254-0063-5e7a", "fuchsia-5254-0063-5e7b", "fuchsia-5254-0063-5e7c"}

	var devicesStdOut string
	for i := 0; i < NUM_DEVICES; i++ {
		devicesStdOut += ipAddrs[i]
		devicesStdOut += " "
		devicesStdOut += deviceNames[i]
		devicesStdOut += "\n"
	}

	deviceMap, err := ffx.ParseDevices(ctx, devicesStdOut)
	if err != nil {
		t_.Error(err)
	}

	devicesFound := 0
	for deviceName := range deviceMap {
		for _, currDeviceName := range deviceNames {
			if currDeviceName == deviceName {
				devicesFound++
				break
			}
		}
	}

	if devicesFound != NUM_DEVICES {
		t_.Error(errors.New("Test devices don't match device map."))
	}

	// Verify empty device list.
	devicesStdOut = "\nNo devices found.\n\n"
	deviceMap, err = ffx.ParseDevices(ctx, devicesStdOut)
	if err != nil {
		t_.Error(err)
	}
	if len(deviceMap) != 0 {
		t_.Error(errors.New("Device map should be empty."))
	}

	// Verify error state with garbage input.
	devicesStdOut = "\nFile not found.\n\n"
	deviceMap, err = ffx.ParseDevices(ctx, devicesStdOut)
	if len(deviceMap) != 0 {
		t_.Error(errors.New("Expected empty map from garbage input."))
	}
	if err == nil {
		t_.Error(errors.New("Expected error from garbage input."))
	}
}
