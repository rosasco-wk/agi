/*
 * Copyright (C) 2022 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// TODO(rosasco): fix the '1'
#if 1 || GAPID_OS_FUCHSIA

#ifndef CORE_CC_FUCHSIA_ZIRCON_SOCKET_CONNECTION_H
#define CORE_CC_FUCHSIA_ZIRCON_SOCKET_CONNECTION_H

#include "core/cc/connection.h"

#include <stdint.h>
#include <memory>

#include <lib/zx/socket.h>

namespace core {

// Connection object using a native socket
class ZirconSocketConnection : public Connection {
 public:
  ZirconSocketConnection(zx::socket&& socket) : mSocket(std::move(socket)) {}
  ~ZirconSocketConnection();

  // Implementation of the Connection interface
  size_t send(const void* data, size_t size) override;
  size_t recv(void* data, size_t size) override;
  const char* error() override;
  std::unique_ptr<Connection> accept(int timeoutMs = NO_TIMEOUT) override;

  void close() override;

 private:
  // The underlying socket for the connection
  zx::socket mSocket;
};

}  // namespace core

#endif  // CORE_CC_FUCHSIA_ZIRCON_SOCKET_CONNECTION_H
#endif  // GAPID_OS_FUCHSIA
