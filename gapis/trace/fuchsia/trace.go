// Copyright (C) 2018 Google Inc.
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
	"bytes"
	"context"
	"time"

	"github.com/google/gapid/gapis/api/sync"
	"github.com/google/gapid/gapis/service/path"

	"github.com/google/gapid/core/app"
	"github.com/google/gapid/core/log"
	"github.com/google/gapid/core/os/device/bind"
	"github.com/google/gapid/core/os/fuchsia"
	"github.com/google/gapid/gapidapk/pkginfo"
	"github.com/google/gapid/gapis/service"
	"github.com/google/gapid/gapis/trace/tracer"
)

const (
	bufferSizeKb                            = uint32(131072)
	counterPeriodNs                         = uint64(50000000)
	durationMs                              = 7000
	gpuCountersDataSourceDescriptorName     = "gpu.counters"
	gpuRenderStagesDataSourceDescriptorName = "gpu.renderstages"
	minimumSupportedApiLevel                = 29
)

// Only update the package list every 30 seconds at most
var packageUpdateTime = 30.0

type fuchsiaTracer struct {
	// b                    ffx.Device
	packages             *pkginfo.PackageList
	lastIconDensityScale float32
	lastPackageUpdate    time.Time
	// v                    validate.Validator
}

/*
func newValidator(dev bind.Device) validate.Validator {
	log.Errf(nil, nil, "fuchsia.newValidator isn't implemented")
	return nil
}

func deviceValidationTraceOptions(ctx context.Context, v validate.Validator) (*service.TraceOptions, error) {
	return nil, log.Errf(ctx, nil, "fuchsia.deviceValidationTraceOptions isn't implemented")
}
*/

func (t *fuchsiaTracer) GetDevice() bind.Device {
	log.Errf(nil, nil, "fuchsia.getDevice isn't implemented")
	return nil
}

func (t *fuchsiaTracer) ProcessProfilingData(ctx context.Context, buffer *bytes.Buffer, capture *path.Capture, handleMappings *map[uint64][]service.VulkanHandleMappingItem, syncData *sync.Data) (*service.ProfilingData, error) {
	return nil, log.Errf(ctx, nil, "fuchsia.ProcessProfilingData isn't implemented")
}

func (t *fuchsiaTracer) Validate(ctx context.Context) error {
	return log.Errf(ctx, nil, "fuchsia.Validate isn't implemented")
}

func (t *fuchsiaTracer) GetPackages(ctx context.Context, isRoot bool, iconDensityScale float32) (*pkginfo.PackageList, error) {
	return nil, log.Errf(ctx, nil, "fuchsia.GetPackages isn't implemented")
}

// NewTracer returns a new Tracer for Fuchsia.
func NewTracer(dev bind.Device) tracer.Tracer {
	log.Errf(nil, nil, "fuchsia.newTracer isn't implemented")
	return nil
}

// TraceConfiguration returns the device's supported trace configuration.
func (t *fuchsiaTracer) TraceConfiguration(ctx context.Context) (*service.DeviceTraceConfiguration, error) {
	return nil, log.Errf(ctx, nil, "fuchsia.TraceConfiguration isn't implemented")
}

func (t *fuchsiaTracer) GetTraceTargetNode(ctx context.Context, uri string, iconDensity float32) (*tracer.TraceTargetTreeNode, error) {
	return nil, log.Errf(ctx, nil, "fuchsia.GetTraceTargetNode isn't implemented")
}

// findBestAction returns the best action candidate for tracing from the given
// list. It is either the launch action, the "main" action if no launch action
// was found, the first-and-only action in the list, or nil.
func findBestAction(l []*pkginfo.Action) *pkginfo.Action {
	log.Errf(nil, nil, "fuchsia.FindBestAction isn't implemented")
	return nil
}

// InstallPackage installs the given package onto the fuchsia device.
// If it is a zip file that contains an apk and an obb file
// then we install them seperately.
// Returns a function used to clean up the package and obb
func (t *fuchsiaTracer) InstallPackage(ctx context.Context, o *service.TraceOptions) (*fuchsia.InstalledPackage, app.Cleanup, error) {
	return nil, nil, log.Errf(ctx, nil, "fuchsia.InstallPackage isn't implemented")
}

func (t *fuchsiaTracer) getActions(ctx context.Context, pattern string) ([]string, error) {
	return nil, log.Errf(ctx, nil, "fuchsia.getActions isn't implemented")
}

func (t *fuchsiaTracer) FindTraceTargets(ctx context.Context, str string) ([]*tracer.TraceTargetTreeNode, error) {
	return nil, log.Errf(ctx, nil, "fuchsia.FindTraceTargets isn't implemented")
}

func (t *fuchsiaTracer) SetupTrace(ctx context.Context, o *service.TraceOptions) (tracer.Process, app.Cleanup, error) {
	return nil, nil, log.Errf(ctx, nil, "fuchsia.SetupTrace isn't implemented")
}
