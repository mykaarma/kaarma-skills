---
name: thinking-first-principles
description: Apply first-principles thinking to break down complex production systems problems into fundamental truths. Use when facing ambiguous requirements, architectural decisions, performance bottlenecks, or when existing solutions don't fit. Helps identify root causes and build solutions from foundational understanding rather than copying patterns.
---

# First-Principles Thinking for Production Systems

## When to Use This Skill

Use first-principles thinking when:
- **Ambiguous requirements**: "We need it to be fast" or "Make it scalable"
- **Architectural decisions**: Choosing databases, queue systems, caching strategies
- **Performance bottlenecks**: Unclear what's causing slowness
- **Existing solutions don't fit**: Off-the-shelf patterns don't match your constraints
- **Debugging complex issues**: Root cause isn't obvious
- **Evaluating trade-offs**: Multiple valid approaches with different costs

**Don't use when**:
- Well-established patterns exist (use existing best practices)
- Time-critical hotfixes (copy working patterns, refine later)
- Simple CRUD operations (standard patterns are fine)

## The Three-Step Framework

### Step 1: Identify Assumptions

List everything you're assuming to be true. Challenge each assumption.

**Example: "We need a faster database"**

Assumptions to challenge:
- Is the database actually slow?
- Is the database the bottleneck?
- What does "faster" mean? (Latency? Throughput? P99?)
- Are we measuring the right thing?
- Could the problem be our queries, not the database?

**Technique**: Ask "Why?" five times to get to root causes.

### Step 2: Break Down to Fundamentals

Reduce the problem to basic truths and constraints.

**Example: Database selection**

Fundamentals:
- Data needs to persist reliably
- We need to read it back with certain latency guarantees
- We have X writes/second, Y reads/second
- Our data has these access patterns: [describe]
- We need consistency guarantees: [ACID vs eventual]
- Our infrastructure constraints: [memory, disk, network]

**Don't include**:
- "Everyone uses PostgreSQL" (not a fundamental truth)
- "NoSQL is web scale" (marketing, not engineering)
- "Our team knows MongoDB" (valid constraint, but separate from technical requirements)

### Step 3: Reason Up from Fundamentals

Build the solution from first principles.

**Example: Database choice**

From fundamentals:
1. We need 10K writes/second → rules out single-node SQL with HDD
2. We need strong consistency for financial data → rules out eventually-consistent stores
3. Our access pattern is mostly key-value lookups → don't need complex joins
4. We can tolerate 50ms P99 read latency → memory caching could help

**Conclusion**: Start with PostgreSQL + read replicas + Redis cache. This satisfies our fundamentals. Only switch to distributed database if we exceed single-node capacity (which we can measure).


## Common Patterns

### Pattern 1: Performance Investigation

**Don't assume**: "The API is slow, we need faster servers"

**First principles**:
1. Measure: What's actually slow? (Network? Database? Compute? External API?)
2. Quantify: How slow? (Mean? Median? P99?)
3. Baseline: What should it be? (Based on workload, not vibes)
4. Bottleneck: What's the limiting factor?
5. Solution: Address the actual constraint

### Pattern 2: Scalability Decisions

**Don't assume**: "We'll need Kubernetes because we're building a SaaS"

**First principles**:
1. Current load: What's our actual traffic? (RPS, concurrent users, data volume)
2. Growth rate: How fast are we growing? (10x in 1 year? 2x in 5 years?)
3. Failure modes: What happens if a server dies?
4. Operational capacity: Can our team run Kubernetes?
5. Cost: What's the TCO of each option?

**Often**: A single server with good monitoring and backups beats a complex distributed system for 90% of startups.

### Pattern 3: Technology Selection

**Don't assume**: "We need microservices and event-driven architecture"

**First principles**:
1. Team size: Can we maintain multiple services? (Each service needs on-call)
2. Change frequency: Do components really need independent deployment?
3. Failure isolation: Do failures need to be contained?
4. Data consistency: Can we tolerate eventual consistency?
5. Network reliability: How do we handle network partitions?

**Tradeoffs**:
- Monolith: Simple ops, shared database, easier transactions, harder to scale team
- Microservices: Complex ops, distributed transactions, easier to scale team, harder to debug

Choose based on your actual constraints, not industry trends.

## Reliability and Performance Trade-offs

### CAP Theorem in Practice

You can't have all three: Consistency, Availability, Partition tolerance.

**First principles**:
- **Banking**: Consistency > Availability (Better to be down than show wrong balance)
- **Social media**: Availability > Consistency (Stale like counts are fine)
- **E-commerce**: Depends on operation (Inventory: Consistency, Reviews: Availability)

### Latency Numbers Every Programmer Should Know

Use these fundamentals to reason about performance:
- L1 cache: 0.5 ns
- L2 cache: 7 ns
- RAM: 100 ns
- SSD read: 16 µs
- Network within datacenter: 500 µs
- Disk seek: 10 ms
- Network cross-continent: 150 ms

**Implication**: If your API is 200ms, adding an SSD won't help. The bottleneck is elsewhere.


## Examples

### Example 1: "Make the API Faster"

**Bad approach**: Add caching, switch to NoSQL, rewrite in Go

**First principles**:
```
1. Measure actual latency: P50=50ms, P99=500ms
2. Profile: 80% of time in database query
3. Analyze query: Full table scan on 10M rows
4. Root cause: Missing database index
5. Solution: Add index, latency drops to P99=50ms
```

**Cost**: 5 minutes to add index vs. weeks to rewrite

### Example 2: "We Need a Message Queue"

**Question**: Do you need a message queue, or do you need async processing?

**First principles**:
- **Need**: Process 1000 jobs/hour without blocking API responses
- **Don't need**: Complex routing, multiple consumers, guaranteed ordering

**Options**:
1. Database-backed queue (PostgreSQL with polling): Simple, reliable, handles 1000/hour easily
2. Redis list: Fast, loses data on crash, good for 10K+/hour
3. RabbitMQ/Kafka: Complex ops, overkill unless you need routing/multiple consumers

**Choose** based on actual requirements, not "industry standard."

### Example 3: "Should We Use Microservices?"

**First principles**:
- **Team size**: 5 engineers
- **Release frequency**: Daily deployments
- **System complexity**: CRUD API + background jobs
- **Scale**: 1000 RPS, single region

**Analysis**:
- Microservices overhead: Multiple repos, CI/CD, monitoring, on-call rotation
- With 5 engineers, you can't staff on-call for 5 services
- 1000 RPS easily handled by monolith
- Daily deployments work fine with monolith + feature flags

**Conclusion**: Start with modular monolith. Split services only when:
- Component needs independent scaling (e.g., expensive ML model)
- Different reliability requirements (core API vs. analytics)
- Team grows beyond 15-20 engineers

## Anti-Patterns to Avoid

### Cargo Cult Engineering

**Bad**: "Netflix uses microservices, so we should too"

**Why it's wrong**: Netflix has 1000+ engineers and billions in revenue. Your constraints are different.

**First principles**: What problems are you actually solving? Choose solutions that fit your constraints.

### Premature Optimization

**Bad**: "We'll use sharded Postgres from day one for scalability"

**Why it's wrong**: Adds complexity before you have the problem. Most companies never reach sharding scale.

**First principles**: Use simple solutions until you have actual scale problems. Then optimize.

### Resume-Driven Development

**Bad**: Choosing technologies because they look good on a resume

**Why it's wrong**: Introduces unnecessary complexity and operational burden.

**First principles**: Choose boring, well-understood technology that fits your constraints.

## Integration with Project Documentation

When working on a specific project:
- **Check project docs first**: See CLAUDE.md or README for established patterns
- **Apply first principles**: When project patterns don't fit, reason from fundamentals
- **Document decisions**: Explain why you chose a different approach
- **Example**: "Project uses REST, but this feature needs streaming data. Using WebSockets because [fundamental requirement]."

## Decision Framework Template

Copy this template when making architectural decisions:

```
## Problem Statement
[Describe the problem in one sentence]

## Constraints
- Performance: [Latency/throughput requirements]
- Scale: [Current and projected load]
- Team: [Size, expertise, on-call capacity]
- Budget: [Cost constraints]
- Reliability: [SLA requirements]

## Assumptions to Challenge
1. [Assumption 1] - Is this actually true?
2. [Assumption 2] - What evidence do we have?
3. [Assumption 3] - What if this changes?

## Fundamentals
- [Fundamental requirement 1]
- [Fundamental requirement 2]
- [Fundamental constraint 1]

## Options Considered
### Option A: [Name]
- Pros: [Based on fundamentals]
- Cons: [Based on fundamentals]
- Cost: [Time/money/complexity]

### Option B: [Name]
- Pros: [Based on fundamentals]
- Cons: [Based on fundamentals]
- Cost: [Time/money/complexity]

## Decision
[Chosen option] because [reasoning from fundamentals]

## Success Criteria
- [Measurable metric 1]
- [Measurable metric 2]

## Rollback Plan
[How to revert if this doesn't work]
```

## Key Takeaways

1. **Challenge assumptions**: Most "requirements" are actually assumptions
2. **Measure, don't guess**: "The database is slow" means nothing without metrics
3. **Reason from constraints**: Your scale, team, and reliability requirements drive decisions
4. **Simple first**: Boring technology usually beats cutting-edge for production systems
5. **Trade-offs are real**: Every decision has costs. Make them explicit.
6. **Document reasoning**: Future you will thank current you

## When This Skill is Complete

You've successfully applied first-principles thinking when:
- You've identified and challenged key assumptions
- You've quantified the actual constraints and requirements
- You've reasoned up from fundamentals rather than copying patterns
- You can explain your decision to someone unfamiliar with the domain
- You have measurable success criteria and a rollback plan

## Architecture Decision Records (ADR)

For significant decisions, use the ADR format (industry standard from AWS, Microsoft, Google):

### ADR Template

```markdown
# ADR-001: [Decision Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Context
[What is the issue that we're seeing that is motivating this decision?]

## Decision
[What is the change that we're proposing and/or doing?]

## Consequences
[What becomes easier or more difficult because of this change?]

## Alternatives Considered
[What other options were evaluated?]
```

### ADR Best Practices (AWS 2024)

1. **Keep ADRs focused**: One decision per ADR
2. **Timely decisions**: 1-3 review sessions max; most decisions are reversible
3. **Immutable once accepted**: Create new ADR to supersede, don't modify
4. **Root in requirements**: Justify with data and engineering principles, not opinions
5. **Focus on "why"**: Reasoning matters more than implementation details

### When to Write an ADR

- Database or storage technology choice
- API design decisions (REST vs GraphQL vs gRPC)
- Framework or language selection
- Architecture patterns (monolith vs microservices)
- Security approach changes
- Breaking changes to public APIs

**Reference**: [AWS ADR Best Practices](https://aws.amazon.com/blogs/architecture/master-architecture-decision-records-adrs-best-practices-for-effective-decision-making/), [Microsoft Azure ADR Guide](https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record)
