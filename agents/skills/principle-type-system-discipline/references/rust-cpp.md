# Rust and C++ examples

Use these examples when a representation or language mechanism needs clarification. Follow the codebase's language version and conventions.

## State variants

In Rust, represent mutually exclusive states as an enum with the data each state needs:

```rust
use std::time::SystemTime;

enum JobState {
    Pending,
    Done { completed_at: SystemTime },
}
```

In C++, use a tagged representation such as `std::variant`:

```cpp
#include <chrono>
#include <variant>

struct Pending {};
struct Done {
    std::chrono::system_clock::time_point completed_at;
};
using JobState = std::variant<Pending, Done>;
```

This avoids a completion flag and an optional timestamp that can disagree. In Rust, avoid a catch-all arm when adding a variant should require updating each consumer. In C++, use visitor overloads for each alternative when incomplete handling should fail compilation. A generic fallback can hide a missing case.

## Distinct identities

Rust newtypes distinguish IDs that share an underlying representation:

```rust
struct UserId(u64);
struct OrderId(u64);
```

C++ wrapper types do the same without implicit conversion between them:

```cpp
#include <cstdint>

struct UserId { std::uint64_t value; };
struct OrderId { std::uint64_t value; };
```

For a constrained value, keep representation access controlled and construct it through validation. A wrapper with an unrestricted public field distinguishes identity but does not enforce value constraints.

## Ownership and lifetime

In Rust, prefer owned values and explicit borrowing that match the required lifetime. In C++, use RAII and owning types such as `std::unique_ptr` when ownership is exclusive. Views and references should not outlive the owner. A `std::span` describes a range but does not own its storage.

Use shared ownership only when the domain needs it. Avoid introducing reference counting to avoid deciding who owns a value.

## Parsing and errors

Parse external data into domain values and return the failure through the project's established error mechanism. Rust commonly uses `Result`. C++ projects may use `std::expected` when their language version supports it, another result type, or exceptions. Keep the convention consistent.

For FFI, raw pointers, or representation casts, isolate the boundary and document the facts required for validity, alignment, ownership, and lifetime. The compiler does not prove those facts merely because a cast compiles.
