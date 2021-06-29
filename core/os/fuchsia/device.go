// Copyright (C) 2021 Google Inc.
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

package fuchsia

import (
	"context"

	"github.com/google/gapid/core/os/device/bind"
	"github.com/google/gapid/core/os/shell"
)

// Device extends the bind.Device interface with capabilities specific to Fuchsia devices.
type Device interface {
	bind.DeviceWithShell
	// Command is a helper that builds a shell.Cmd with the device as its target.
	Command(name string, args ...string) shell.Cmd
	// Pulls the remote file to the local one.
	Pull(ctx context.Context, remote, local string) error
	// Pushes the local file to the remote one.
	Push(ctx context.Context, local, remote string) error
	// SetSystemProperty sets the system property with the given string value.
	SetSystemProperty(ctx context.Context, name, value string) error
	// SystemProperty returns the system property in string.
	SystemProperty(ctx context.Context, name string) (string, error)
}
