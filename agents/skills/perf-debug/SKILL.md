---
name: perf-debug
description: "Use when debugging a performance issue or a regression"
---

# Debugging performance issues

## General guideance

1. Every hypothesis must be grounded with real-world measurement. Use a profiler or a microbenchmark to back your findings.
2. Run workloads in their native environment. If the code is supposed to run on a desktop, do not try to pin cores and isolate the process. That is unfaithful to how the code will be executed in production.
3. For CPU or memory bound problems use TMA analysis to figure out how much headroom you have.
4. These are the techniques used to combat CPU-bound issues:
   1. Don't do it. If some result is unused, just cut it.
   2. Use data-oriented design. Always start with reasoning about how data is stored in memory and whether this is the most optimal layout given CPU architecture.
   3. Design optimal algorithms - exploit data parallelism and knowledge of modern CPU pipelines.

## Miniperf and TMA methodology for native code

Use `mperf` for every measurement it supports. Reach for `perf` only for what `mperf` lacks, such as scheduler traces.

Six rules decide whether the work is accepted:

1. Every change starts from a measurement that names the bottleneck. A hotspot list, a self-time table, or a counter of work done (rows, calls, iterations) does not name one.
2. Top-down numbers come from the tool. Read them from `tma_summary`, `tma`, or `mperf stat --topdown`. Do not compute your own formulas over `pmu_*` columns or hand-picked raw events and call the result TMA. If `mperf` lacks a level on this CPU, say so and label anything you derive as derived.
3. After a change, record again and compare the same tree. Wall time alone does not show whether the hypothesis was right.
4. If sampling is unavailable, stop. Do not fall back to reading the code, timing by hand, or reasoning about what is probably slow. See "When sampling is unavailable" below.
5. Use `/how` skill to ground your hypotheses.
6. Plan the fix from the trace. If it crosses a function boundary, architect first. Delegate implementation to a subagent.

### Install

```sh
command -v mperf && mperf doctor
```

If `mperf` is missing, install the release archive. `mperf` finds its helper libraries relative to its own executable, so keep the whole tree together and symlink the binary. Do not copy `bin/mperf` on its own.

```sh
target="$(uname -m)-unknown-linux-gnu"
tag=$(gh release list -R frontiers-labs/miniperf --json tagName -q '[.[].tagName | select(startswith("v"))][0]')
gh release download "$tag" -R frontiers-labs/miniperf -p "miniperf-*-$target.tar.gz*"
sha256sum -c miniperf-*.sha256
mkdir -p ~/.local/opt/miniperf ~/.local/bin
tar xzf miniperf-*-$target.tar.gz -C ~/.local/opt/miniperf --strip-components=1
ln -sf ../opt/miniperf/bin/mperf ~/.local/bin/mperf
```

Releases lag master. Build from source when the release rejects `record -s tma` on this CPU or lacks a fix you need. The packaging script produces the same archive, with DynamoRIO and QEMU included, and needs Rust 1.85 or newer and `cc`:

```sh
git clone https://github.com/frontiers-labs/miniperf.git && cd miniperf
utils/package-miniperf.sh "$(rustc -vV | sed -n 's/^host: //p')" dist
```

Unpack `dist/miniperf-*.tar.gz` the same way. For `stat`, `snapshot`, and `tma` alone, `cargo build --release -p mperf` is enough.

Run `mperf doctor` and read every row that is not `ok`. `perf_event_paranoid` above 2 blocks everything. Level 0 or lower adds system-wide events, and -1 lifts the per-user sampling buffer budget on machines with many CPUs. The snapshot BPF collector needs root and `bpftrace`.

#### When sampling is unavailable

Sampling is unavailable when `mperf doctor` reports a blocker on `perf_event_paranoid` or `hardware counters`, or when `mperf record` fails to open its counters or map its buffers. A container or VM without PMU access shows the same symptoms.

Check for passwordless sudo with `sudo -n true`.

- If it succeeds, enable sampling yourself, rerun `mperf doctor`, and tell the user what you changed:

  ```sh
  sudo -n sysctl -w kernel.perf_event_paranoid=-1 kernel.kptr_restrict=0
  ```

- If it fails, stop the task and ask the user to enable sampling. Quote the failing doctor row or the error, and give the exact command to run. Wait for the answer. Do not continue the investigation without measurements.

A degraded row is different from a blocker. A snapshot without the BPF collector still records the other resources, so continue and say which evidence is missing. Stop only when the missing collector is the one the question depends on.

### Prepare the run

- Build optimized with debug info: `-O2 -g` for C, `CARGO_PROFILE_RELEASE_DEBUG=true cargo build --release` for Rust. `mperf` unwinds through branch records or DWARF, so a separate frame-pointer build is optional.
- Make the run last at least 5 seconds. Counter groups take turns on the hardware, so a short run gives noisy level-2 values. Wrap a short command in a script that repeats it.
- Pin `mperf` itself, not only the workload: `taskset -c 4 mperf record ...`. Pick a core whose SMT sibling is idle and reuse the same core for every run you compare.
- Give each run a new directory named after the build and input, under the project's artifact directory. `mperf record` refuses an existing directory. Keep the baseline recording until the work is done.
- Keep what `mperf` prints. Redirecting everything to `/dev/null` hides the capture fidelity line and the warnings that say which collectors did not run.

```sh
taskset -c 4 mperf record -s tma -o prof/base-O2 -- ./workload > prof/base-O2.log 2>&1
grep -aE '^(Capture fidelity|Warning|Error)' prof/base-O2.log
```

### Measure

Counts for a whole run, with no profile:

```sh
mperf stat -- ./workload                      # cycles, instructions, IPC, LLC and branch MPKI
mperf stat --topdown -l 2 -- ./workload       # top-down tree, two levels
mperf stat -e cycles,instructions,<event> -- ./workload
mperf stat -p <pid>                           # count a running process until it exits
mperf list | grep -i tlb                      # event and metric names for this CPU
```

Check the `Scaling` column. 1.00 is an exact count. Anything higher is an estimate, so ask for fewer events per run when you need exact ratios. `mperf stat` has no repeat flag. Run it five times and report the median and the spread.

Profiles:

| Scenario | Question it answers | Notes |
|---|---|---|
| `snapshot` | Which resource is the process tree short of? | 99 Hz. Launch or attach with `-p <pid>`. Bound it with `--duration 30s`. Run under `sudo` for scheduler latency, block I/O latency, and TCP retransmits. |
| `tma` | Which functions are hot, and why is each one slow? | 1000 Hz. Launch only. Also records precise memory samples when the CPU has PEBS, IBS, or SPE. |
| `mem` | How big is the working set, and how well does it use the cache? | Replays the program under DynamoRIO or QEMU, about 20 times slower. Use a small input. |
| `roofline` | How close is each loop to the compute and bandwidth ceilings? | For numerical kernels. Same replay cost. |

```sh
sudo mperf record -s snapshot -o prof/snap --duration 30s -- ./server
taskset -c 4 mperf record -s tma -o prof/tma -- ./workload
taskset -c 4 mperf record -s mem -o prof/mem -- ./workload --small-input
```

### Query

`mperf query DIR 'SQL'` runs one read-only DuckDB statement. Facts that prevent most failed queries:

- Output stops at 50 rows whatever the SQL says. Pass `--max-rows N`, up to 10000.
- Use `-f json` when a script reads the result. Text output is for reading.
- Metric columns hold fractions between 0 and 1. Text output prints the known ones as percentages.
- Every selected expression needs a unique `AS` alias.
- `tma_summary.metric` uses dots, as in `be_bound.memory_bound`. Columns in `tma` use underscores, as in `be_bound_memory_bound`. The metric set depends on the CPU, so list it before naming columns.
- `mperf query help` prints the table list. `PRAGMA table_info('tma')` prints the columns.

Check that the recording is trustworthy before reading it:

```sql
SELECT scenario, rung, status, reason FROM capture_fidelity;

SELECT count(*) AS samples, count(DISTINCT thread_id) AS threads, count(DISTINCT cpu) AS cpus
FROM pmu_counters;
```

Fewer than a few thousand samples means the run was too short.

Whole-run top-down verdict, then the timeline to spot phases:

```sql
SELECT metric, value, verdict FROM tma_summary ORDER BY value DESC;

PIVOT (SELECT start_ns, metric, value FROM tma_intervals WHERE metric NOT LIKE '%.%')
ON metric USING first(value) ORDER BY start_ns;
```

Hot functions with the reason each one is slow. Add the level-2 columns under the dominant category:

```sql
SELECT func_name, total, ipc, retiring, fe_bound, be_bound, bad_speculation,
       be_bound_memory_bound, fe_bound_fetch_latency
FROM tma ORDER BY total DESC LIMIT 20;
```

`tma` attributes samples to the leaf function. For inclusive time, expand the call stacks. `pmu_counters.call_stack` is a list of instruction pointers, leaf first, stored as text.

```sql
-- Inclusive share of every function
WITH s AS (SELECT unique_id, pmu_cycles AS c, CAST(call_stack AS UBIGINT[]) AS frames FROM pmu_counters),
     f AS (SELECT DISTINCT s.unique_id, s.c, m.func_name
           FROM s, unnest(s.frames) AS u(ip) JOIN proc_map m ON m.ip = u.ip)
SELECT func_name, round(100.0 * sum(c) / (SELECT sum(c) FROM s), 1) AS inclusive_pct
FROM f GROUP BY 1 ORDER BY 2 DESC LIMIT 30;
```

To look inside one subtree, list the leaf functions under a frame with the tool's own top-down columns for each. Replace the `LIKE` pattern.

```sql
WITH s AS (SELECT unique_id, ip, pmu_cycles AS c, CAST(call_stack AS UBIGINT[]) AS frames FROM pmu_counters),
     sub AS (SELECT DISTINCT s.unique_id, s.ip, s.c
             FROM s, unnest(s.frames) AS u(ip) JOIN proc_map m ON m.ip = u.ip
             WHERE m.func_name LIKE '%parse_request%'),
     leaf AS (SELECT m.func_name, sum(sub.c) AS c FROM sub JOIN proc_map m ON m.ip = sub.ip GROUP BY 1)
SELECT leaf.func_name,
       round(100.0 * leaf.c / (SELECT sum(c) FROM leaf), 1) AS self_pct_of_subtree,
       round(100.0 * (SELECT sum(c) FROM leaf) / (SELECT sum(c) FROM s), 1) AS subtree_pct_of_run,
       t.ipc, t.retiring, t.fe_bound, t.be_bound, t.bad_speculation
FROM leaf JOIN tma t USING (func_name) ORDER BY 2 DESC LIMIT 20;
```

Callers of a function that is hot only because many places call it, such as `malloc` or `memcpy`:

```sql
WITH fn AS (SELECT ip FROM proc_map WHERE func_name = 'malloc'),
     s AS (SELECT unique_id, pmu_cycles AS c, CAST(call_stack AS UBIGINT[]) AS frames FROM pmu_counters),
     e AS (SELECT unique_id, c, frames, generate_subscripts(frames, 1) AS i FROM s),
     hit AS (SELECT e.unique_id, e.c, e.frames, max(e.i) AS i FROM e JOIN fn ON fn.ip = e.frames[e.i] GROUP BY ALL)
SELECT m.func_name AS caller, round(100.0 * sum(hit.c) / (SELECT sum(c) FROM hit), 1) AS pct
FROM hit JOIN proc_map m ON m.ip = hit.frames[hit.i + 1] GROUP BY 1 ORDER BY 2 DESC LIMIT 15;
```

For a quick look without SQL, `flamegraph_cycles.folded` in the recording holds one `root;...;leaf count` line per stack and works with `grep` and `awk`.

Hot source lines and hot instructions:

```sql
SELECT m.func_name, m.file_name, m.line,
       round(100.0 * sum(p.pmu_cycles) / (SELECT sum(pmu_cycles) FROM pmu_counters), 1) AS pct
FROM pmu_counters p JOIN proc_map m USING (ip) GROUP BY ALL ORDER BY pct DESC LIMIT 20;

SELECT s.func_name, hex(s.address) AS addr, s.samples, s.cycles, l.instruction
FROM assembly_address_stats s
LEFT JOIN assembly_lines l ON l.runtime_address = s.address AND l.module_path = s.module_path
WHERE s.func_name = 'chase' ORDER BY s.cycles DESC LIMIT 20;
```

A sample lands one or two instructions after the one that stalled, so read the instruction above the hot address too.

Memory, from a `tma` recording on a CPU with precise sampling:

```sql
-- Where loads were served from, and what they cost
SELECT level, count(*) AS samples, round(avg(latency_cycles)) AS avg_latency
FROM mem_samples GROUP BY 1 ORDER BY 2 DESC;

-- Functions whose loads go to DRAM. This call_stack is symbolized, root first.
SELECT split_part(call_stack, ';', -1) AS func, count(*) AS samples,
       count(*) FILTER (WHERE level = 'ram') AS dram, round(avg(latency_cycles)) AS avg_latency
FROM mem_samples GROUP BY 1 ORDER BY dram DESC LIMIT 15;

-- Allocations that own the missing addresses, and false-sharing candidates
SELECT alloc_site, allocated_bytes, sample_count, ram_count, avg_latency_cycles
FROM alloc_site_memory ORDER BY ram_count DESC LIMIT 10;

SELECT hex(cache_line) AS line, sample_count, distinct_threads, hitm_count
FROM cacheline_contention WHERE distinct_threads > 1 ORDER BY hitm_count DESC LIMIT 10;
```

From a `mem` recording:

```sql
SELECT accessed_footprint_bytes, peak_rss_bytes, cold_fraction, achieved_gbytes_per_second,
       bandwidth_utilization, quality FROM memory_summary;

-- Miss ratio the working set would have at each cache size
SELECT cache_bytes, miss_ratio FROM memory_miss_ratio
WHERE cache_bytes IN (32768, 1048576, 33554432, 1073741824) ORDER BY 1;
```

From a `snapshot` recording:

```sql
SELECT rank, severity, resource, finding, evidence, recommendation FROM snapshot_findings ORDER BY rank;

SELECT resource, category, metric, value, unit FROM snapshot_summary
WHERE scope = 'process_tree' ORDER BY resource, category;

SELECT name, status, message FROM snapshot_collectors WHERE status <> 'available';

SELECT func_name, total, ipc, cache_mpki, branch_mpki FROM hotspots ORDER BY total DESC LIMIT 20;
```

Compare two recordings. Paths inside `read_parquet` are relative to the current directory.

```sql
-- mperf query prof/after "..."
SELECT metric, b.value AS before, a.value AS after, a.value - b.value AS delta
FROM tma_summary a JOIN read_parquet('prof/before/tma_summary.parquet') b USING (metric)
ORDER BY abs(a.value - b.value) DESC;

SELECT func_name, b.total AS before, a.total AS after, b.ipc AS ipc_before, a.ipc AS ipc_after
FROM tma a FULL JOIN read_parquet('prof/before/tma.parquet') b USING (func_name)
ORDER BY greatest(coalesce(a.total, 0), coalesce(b.total, 0)) DESC LIMIT 20;
```

Shares hide a speedup that shrinks everything equally. Compare `cycles` as well when the total changed.

### Methodology

Work from the whole system down to one instruction. Write down each reading before acting on it.

1. Define the target. Name the workload, the input, the metric, and the number that counts as done. Measure the baseline five times, pinned, and keep the median and the spread. A later gain smaller than the spread is not a gain.

2. Survey the system with `snapshot` and the USE method. For CPU, memory, disk, and network, read utilization, saturation, and errors from `snapshot_findings` and `snapshot_summary`. Read the coverage rows too, because a collector that did not run cannot report a problem. CPU utilization is a share of the whole machine, so one saturated thread on 32 CPUs shows as 3% and "has headroom". Compare `user_time + system_time` with wall time to count busy threads.

3. Classify the problem.
   - CPU time close to wall time times the thread count means CPU bound. Continue with step 4.
   - CPU time far below wall time means the program waits. Sampling shows only on-CPU time, so a hotspot list will mislead you. Use the snapshot evidence for run-queue latency, block I/O latency, memory pressure, and retransmits, then `strace -c -f`, `perf sched`, or `bpftrace` for the specific wait.
   - A "host clocked below its ceiling" finding or thermal throttling invalidates timing comparisons. Fix the machine state first.

4. For CPU-bound work, walk the top-down tree with a `tma` recording.
   1. Level 1 for the whole run from `tma_summary`. The dominant category is the question to answer.
   2. Level 2 under that category.
   3. The functions and subtrees that carry that category, with the subtree query. A subtree's share of the run bounds what fixing it can gain.
   4. The source lines and instructions inside them.
   5. The specific cause, counted with `mperf stat -e` using events from `mperf list` for that category, with `Scaling` at 1.00. Report these per thousand instructions.
   6. One hypothesis that explains the numbers, and one change that tests it.

   | Category | Meaning | Look next at | Typical fixes |
   |---|---|---|---|
   | Retiring high, IPC high | The CPU is busy with useful work. There is too much of it. | Inclusive time, callers, algorithm | Do less work, better algorithm, vectorize, cache results |
   | Retiring, microcode share high | Microcoded instructions | Hot instructions | Avoid division, string ops, denormals |
   | Frontend bound, fetch latency | Instruction cache or ITLB misses, resteers | Icache and ITLB events, code size, indirect calls | Smaller hot code, fewer distinct code paths per item, batch work by kind, PGO, huge pages for text |
   | Frontend bound, fetch bandwidth | Decoder delivers too few ops per cycle | Op-cache events | Alignment, simpler instruction mix |
   | Bad speculation | Mispredicted branches | Branch misses per function, the hot branch | Branchless code, sort or partition data, hoist the test out of the loop |
   | Backend bound, memory | Loads wait on cache or DRAM | `mem_samples`, `alloc_site_memory`, then `mem` | Smaller or denser data, sequential access, prefetch, fewer pointers, fix false sharing |
   | Backend bound, core | Execution ports or dependency chains | Hot instructions, IPC | Break dependency chains, cheaper operations |

5. For memory-bound code, use `mem_samples` to find the loads and the allocations behind them. Run `mem` when you need the working set size, the miss-ratio curve, or DRAM bandwidth use.

6. Verify. Rebuild, record with the same pinning and input into a new directory, and run the comparison queries. The targeted category should shrink in the targeted subtree. If wall time moved and the category did not, the explanation was wrong, so find out what changed. If nothing moved, revert the change and go back to the tree.

Check these before trusting any reading:

- `smt_contention` in `tma_summary` should be near zero. A busy sibling thread takes dispatch slots and distorts every other category. Pin to a different core or wait for the machine to go idle.
- Small negative values mean zero. Counter-based level-1 values can exceed 1.0 on some CPUs. Trust the ranking and the level-2 split.
- A `NULL` metric means a counter group was dropped. Check `mperf doctor` and the notices in the log.
- A large `[unknown]` share means missing debug info. Rebuild with `-g` or set `DEBUGINFOD_URLS` and `MINIPERF_DEBUGINFOD=1`.
- Compare only runs taken on the same machine with the same pinning, input, and build flags.

### Replace perf habits

| Instead of | Use |
|---|---|
| `perf record -g` then `perf report --stdio \| grep \| head` | `mperf record -s tma`, then the `tma` and inclusive queries |
| `perf report --children` | The inclusive query |
| `perf script` piped to a custom stack parser | The call-stack queries, or `flamegraph_cycles.folded` |
| `perf annotate --stdio -s sym` | `assembly_address_stats` joined with `assembly_lines` |
| `perf stat -e r0c0,r076,...` and your own ratios | `mperf stat --topdown -l 2`, or `mperf stat -e` with names from `mperf list` |
| `perf diff a.data b.data` | The comparison queries |
| `perf mem`, `perf c2c` | `mem_samples`, `alloc_site_memory`, `cacheline_contention` |
