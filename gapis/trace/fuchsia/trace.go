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
	"fmt"
	"io"
	"os"
	"sync/atomic"
	"time"

	perfetto_pb "protos/perfetto/config"

	"github.com/google/gapid/core/app"
	"github.com/google/gapid/core/app/status"
	"github.com/google/gapid/core/event/task"
	"github.com/google/gapid/core/log"
	"github.com/google/gapid/core/os/device/bind"
	"github.com/google/gapid/core/os/file"
	"github.com/google/gapid/core/os/fuchsia"
	"github.com/google/gapid/gapis/api"
	"github.com/google/gapid/gapis/api/sync"
	"github.com/google/gapid/gapis/service"
	"github.com/google/gapid/gapis/service/path"
	"github.com/google/gapid/gapis/trace/android/validate"
	"github.com/google/gapid/gapis/trace/tracer"

	"github.com/golang/protobuf/proto"

	"github.com/google/gapid/core/app"
	"github.com/google/gapid/core/app/status"
	"github.com/google/gapid/core/event/task"
	"github.com/google/gapid/core/log"
	"github.com/google/gapid/core/os/device/bind"
	"github.com/google/gapid/core/os/file"
	"github.com/google/gapid/gapis/api"
	"github.com/google/gapid/gapis/api/sync"
	"github.com/google/gapid/gapis/service"
	"github.com/google/gapid/gapis/service/path"
	"github.com/google/gapid/gapis/trace/android/validate"
	"github.com/google/gapid/gapis/trace/tracer"
)

type traceSession struct {
	device  fuchsia.Device
	options *service.TraceOptions
}

// Capture connects to this trace and waits for a capture to be delivered.
// It copies the capture into the supplied writer.
// If the process was started with the DeferStart flag, then tracing will wait
// until start is fired.
// Capturing will stop when the stop signal is fired (clean stop) or the
// context is cancelled (abort).
func (s *traceSession) Capture(ctx context.Context, start task.Signal, stop task.Signal, ready task.Task, w io.Writer, written *int64) (size int64, err error) {
	// Create trace file.
	traceFile, err := file.Temp()
	if err != nil {
		return 0, log.Err(ctx, err, "Trace Temp file creation")
	}
	defer file.Remove(traceFile)

	// Signal that we are ready to start.
	atomic.StoreInt64(written, 1)

	// Verify defer start option.
	if s.options.DeferStart && !start.Wait(ctx) {
		return 0, log.Err(ctx, nil, "Trace Cancelled")
	}

	// Initiate tracing.
	if err := s.device.StartTrace(ctx, s.options, traceFile, stop, ready); err != nil {
		return 0, err
	}

	// Wait for capture to stop.
	duration := time.Duration(float64(s.options.Duration) * float64(time.Second))
	if duration > 0 {
		stop.TryWait(ctx, duration)
	} else {
		stop.Wait(ctx)
	}

	// Stop tracing.
	if err := s.device.StopTrace(ctx, traceFile); err != nil {
		return 0, err
	}

	// Copy trace file contents to output variables.
	traceFileSize := traceFile.Info().Size()
	atomic.StoreInt64(written, traceFileSize)
	fh, err := os.Open(traceFile.System())
	if err != nil {
		return 0, log.Err(ctx, err, fmt.Sprintf("Failed to open %s", traceFile))
	}

	return io.Copy(w, fh)
}

type fuchsiaTracer struct {
	device fuchsia.Device
	validator validate.Validator
}

// TraceConfiguration returns the device's supported trace configuration.
func (t *fuchsiaTracer) TraceConfiguration(ctx context.Context) (*service.DeviceTraceConfiguration, error) {
	return &service.DeviceTraceConfiguration{
		Types:                []*service.TraceTypeCapabilities{tracer.FuchsiaTraceOptions()},
		ServerLocalPath:      false,
		CanSpecifyCwd:        true,
		CanUploadApplication: false,
		CanSpecifyEnv:        true,
		PreferredRootUri:     "/",
		HasCache:             false,
	}, nil
}

// GetTraceTargetNode returns a TraceTargetTreeNode for the given URI
// on the device
func (t *fuchsiaTracer) GetTraceTargetNode(ctx context.Context, uri string, iconDensity float32) (*tracer.TraceTargetTreeNode, error) {
	return nil, nil
}

// FindTraceTargets finds TraceTargetTreeNodes for a given search string on
// the device
func (t *fuchsiaTracer) FindTraceTargets(ctx context.Context, uri string) ([]*tracer.TraceTargetTreeNode, error) {
	return nil, nil
}

// SetupTrace starts the application on the device, and causes it to wait
// for the trace to be started. It returns the process that was created, as
// well as a function that can be used to clean up the device
func (t *fuchsiaTracer) SetupTrace(ctx context.Context, o *service.TraceOptions) (tracer.Process, app.Cleanup, error) {
	session := &traceSession{
		device:  t.device,
		options: o,
	}
	return session, nil, nil
}

// GetDevice returns the device associated with this tracer
func (t *fuchsiaTracer) GetDevice() bind.Device {
	return t.device
}

// ProcessProfilingData takes a buffer for a Perfetto trace and translates it into
// a ProfilingData
func (t *fuchsiaTracer) ProcessProfilingData(ctx context.Context, buffer *bytes.Buffer,
	capture *path.Capture, staticAnalysisResult chan *api.StaticAnalysisProfileData,
	handleMapping map[uint64][]service.VulkanHandleMappingItem, syncData *sync.Data) (*service.ProfilingData, error) {

	<-staticAnalysisResult // Ignore the static analysis result.
	return nil, nil
}

// TODO(rosasco): this func should be platform agnostic.  Consolidate
// with Android version.
func deviceValidationTraceOptions(ctx context.Context, v validate.Validator) *service.TraceOptions {
	counters := v.GetCounters()
	ids := make([]uint32, len(counters))
	for i, counter := range counters {
		ids[i] = counter.Id
	}
	return &service.TraceOptions{
		DeferStart: true,
		PerfettoConfig: &perfetto_pb.TraceConfig{
			Buffers: []*perfetto_pb.TraceConfig_BufferConfig{
				{SizeKb: proto.Uint32(bufferSizeKb)},
			},
			DurationMs: proto.Uint32(durationMs),
			DataSources: []*perfetto_pb.TraceConfig_DataSource{
				{
					Config: &perfetto_pb.DataSourceConfig{
						Name: proto.String(gpuRenderStagesDataSourceDescriptorName),
					},
				},
				{
					Config: &perfetto_pb.DataSourceConfig{
						Name: proto.String(gpuCountersDataSourceDescriptorName),
						GpuCounterConfig: &perfetto_pb.GpuCounterConfig{
							CounterPeriodNs: proto.Uint64(counterPeriodNs),
							CounterIds:      ids,
						},
					},
				},
			},
		},
	}
}

// Validate validates the GPU profiling capabilities of the given device and returns
// an error if validation failed or the GPU profiling data is invalid.
func (t *fuchsiaTracer) Validate(ctx context.Context, enableLocalFiles bool) (*service.DeviceValidationResult, error) {
	ctx = status.Start(ctx, "Fuchsia Device Validation")
	defer status.Finish(ctx)
	
	device := t.device.(fuchsia.Device);
	traceOpts := deviceValidationTraceOptions(ctx, t.validator);

	return &service.DeviceValidationResult{}, nil
}

func NewTracer(d bind.Device) tracer.Tracer {
	return &fuchsiaTracer{device: d.(fuchsia.Device)}
}
