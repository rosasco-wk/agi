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
	"fmt"
	"testing"

	"github.com/google/gapid/core/assert"
	"github.com/google/gapid/core/log"
	"github.com/google/gapid/core/os/device"
	"github.com/google/gapid/core/os/fuchsia/ffx"
	"github.com/google/gapid/core/os/shell/stub"
)

func TestParseDevices(t_ *testing.T) {
	ctx := log.Testing(t_)
	defer func() { devices.Handlers[0] = validDevices }()
	expected := &device.Instance{
		Serial: "production_device",
		Name:   "flame",
		Configuration: &device.Configuration{
			OS: &device.OS{
				Kind:         device.Fuchsia,
				Name:         "Fuchsia",
				Build:        "flame-user 10 QQ1A.191003.005 5926727 release-keys",
				MajorVersion: 1,
				MinorVersion: 0,
				PointVersion: 0,
				APIVersion:   1,
			},
			Hardware: &device.Hardware{
				Name: "flame",
			},
			ABIs: []*device.ABI{device.FuchsiaARM64v8a},
		},
	}
	expected.GenID()
	got, err := ffx.Devices(ctx)
	assert.For(ctx, "Normal devices").ThatError(err).Succeeded()
	assert.For(ctx, "Normal devices").That(got.FindBySerial(expected.Serial).Instance()).DeepEquals(expected)

	devices.Handlers[0] = emptyDevices
	got, err = ffx.Devices(ctx)
	assert.For(ctx, "Empty devices").ThatError(err).Succeeded()
	assert.For(ctx, "Empty devices").ThatSlice(got).IsEmpty()

	devices.Handlers[0] = invalidDevices
	_, err = ffx.Devices(ctx)
	assert.For(ctx, "Invalid devices").ThatError(err).HasCause(ffx.ErrInvalidDeviceList)

	devices.Handlers[0] = invalidStatus
	_, err = ffx.Devices(ctx)
	assert.For(ctx, "Invalid status").ThatError(err).HasCause(ffx.ErrInvalidStatus)

	devices.Handlers[0] = notDevices
	_, err = ffx.Devices(ctx)
	assert.For(ctx, "Not devices").ThatError(err).HasCause(ffx.ErrNoDeviceList)

	devices.Handlers[0] = &stub.Response{WaitErr: fmt.Errorf("Not connected")}
	_, err = ffx.Devices(ctx)
	assert.For(ctx, "not connected").ThatError(err).HasMessage(`Process returned error
   Cause: Not connected`)
}
