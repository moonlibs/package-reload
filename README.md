<a href="http://tarantool.org">
   <img src="https://avatars2.githubusercontent.com/u/2344919?v=2&s=250"
align="right">
</a>

## Overview

`package.reload` is a Lua package for hot-reloading Tarantool packages. It may come in handy if you have a large in-memory dataset and need to often deploy code changes.

## How it works

When first loaded, `package.reload` lists all the currently loaded packages **without reloading them**:

    1st load. loaded: fiber, ffi, io, http.client.driver, console, digest, json, uri, jit.dis_x64, box.internal.gc, crypto, net.box, internal.argparse, jit.bcsave, jit.opt, uuid, fio, pwd, internal.trigger, jit.p, jit.vmdef, os, string, debug, jit.profile, socket, tap, coroutine, net.box.lib, jit.dump, pickle, msgpack, jit.dis_x86, box.backup, jit, jit.v, buffer, box, yaml, xlog, errno, bit, box.internal, jit.zone, package, msgpackffi, csv, jit.bc, help.en_US, title, box.internal.session, tarantool, strict, fun, table.new, math, help, table.clear, _G, http.client, jit.util, log, table, clock, iconv
    ---
    ...

On subsequent calls, `package.reload` reloads all the packages that have been loaded since the previous call to `package.reload`. Suppose you have loaded three packages: `avro_schema`, `expirationd`, and `memcached`. Then after calling `package.reload` you should see a similar output:

    2nd load. Unloading {memcached, avro_schema.compiler, avro_schema.runtime, avro_schema.il, avro_schema, expirationd, avro_schema.backend, avro_schema.frontend}
    reload:cleanup...
    reload:cleanup finished
    ---
    …
