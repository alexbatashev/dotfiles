---
name: principle-type-system-discipline
description: Model invariants, ownership, and domain values with strong types, especially in Rust and C++.
---

# Type system discipline

Use strong types to encode the states and operations the domain permits. Prefer representations that cannot construct contradictory states. Give semantically different values, such as user IDs and order IDs, distinct types.

Make ownership and lifetime explicit. Use Rust's ownership and borrowing rules, or C++ RAII and appropriate owning and view types. Do not introduce shared ownership without a domain reason.

Parse external data at trust boundaries. Keep constrained values behind constructors or functions that establish their invariants. Trust those established guarantees downstream and check state transitions the type system cannot prove.

Handle variants explicitly when a new variant must force callers to reconsider their behavior. Derive protocol and schema types from their authoritative definitions where practical.

Use casts only with an established reason. Keep unsafe code, FFI, and representation conversions narrow, and document the invariants the compiler cannot verify. Do not bypass a type error to hide a design mismatch.

Read [Rust and C++ examples](references/rust-cpp.md) when choosing the language mechanism. In other typed languages, apply the same principles through their idioms.

Strengthen types where they express a real domain distinction or make an operation valid. Avoid precision that adds ceremony without improving correctness or the caller's understanding.
