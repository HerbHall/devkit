<overview>
Common requirement patterns for different project types. Use these as starting points when gathering requirements.
</overview>

<cli_tools>
**CLI Tool Patterns**

Common functional requirements:

- Command-line argument parsing with help text
- Input validation with clear error messages
- Exit codes following conventions (0=success, non-zero=error)
- Support for stdin/stdout piping
- Configuration file support (optional)
- Verbose/quiet output modes

Common non-functional requirements:

- Startup time < 500ms for simple operations
- Clear, actionable error messages
- Works without internet (unless explicitly networked)
- No installation beyond runtime dependencies

Typical acceptance criteria:

- `--help` displays usage information
- Invalid input returns non-zero exit code with error message
- Can be used in shell scripts/pipelines
</cli_tools>

<libraries_apis>
**Library/API Patterns**

Common functional requirements:

- Public API with clear entry points
- Comprehensive error handling with typed exceptions
- Thread safety specifications
- Versioning strategy (semver)

Common non-functional requirements:

- API response time targets
- Memory usage limits
- Backward compatibility policy
- Documentation coverage (all public methods)

Typical acceptance criteria:

- 100% of public API documented
- Breaking changes follow deprecation policy
- Unit test coverage > 80%
</libraries_apis>

<windows_gui>
**Windows GUI Application Patterns**

Common functional requirements:

- Standard window controls (minimize, maximize, close)
- Keyboard navigation (Tab, Enter, Escape)
- Settings persistence across sessions
- File operations (open, save, save as) if applicable
- Undo/redo for data operations

Common non-functional requirements:

- DPI awareness / scaling support
- Responsive UI (no freezing on long operations)
- Startup time < 3 seconds
- Memory usage appropriate to task
- Windows version compatibility (specify minimum)

Typical acceptance criteria:

- Works on Windows 10 and 11
- Handles high-DPI displays correctly
- Long operations show progress/can be cancelled
- Settings preserved after restart
</windows_gui>

<cross_cutting>
**Cross-Cutting Patterns**

These apply to most projects:

**Error Handling**

- FR: System provides clear error messages for all failure modes
- AC: Error messages include what went wrong and suggested fix

**Logging**

- FR: System logs significant events for debugging
- AC: Logs include timestamp, severity, and context

**Configuration**

- FR: Configurable values are externalized from code
- AC: Config changes don't require rebuild

**Documentation**

- FR: User documentation explains all features
- AC: New user can complete basic workflow using docs only
</cross_cutting>

<security_patterns>
**Security Requirement Patterns**

For projects handling sensitive data:

**Authentication**

- FR: System authenticates users before access
- AC: Invalid credentials rejected with generic error

**Authorization**

- FR: System enforces role-based access control
- AC: Users can only access authorized resources

**Data Protection**

- FR: Sensitive data encrypted at rest
- FR: Sensitive data encrypted in transit
- AC: Data unreadable without proper keys

**Input Validation**

- FR: All user input validated before processing
- AC: Invalid input rejected without processing

**Secrets Management**

- FR: Credentials never stored in code
- AC: Secrets loaded from environment/vault only
</security_patterns>

<performance_patterns>
**Performance Requirement Patterns**

Templates for common scenarios:

**Response Time**

- NFR: {Operation} completes in < {X}ms at {Y}th percentile
- Measurement: Automated performance tests, APM tools

**Throughput**

- NFR: System handles {X} {operations}/second sustained
- Measurement: Load testing with realistic workload

**Resource Usage**

- NFR: Memory usage < {X}MB under typical load
- NFR: CPU usage < {X}% during idle periods
- Measurement: Profiling under representative workload

**Scalability**

- NFR: Performance degrades < {X}% when load doubles
- Measurement: Load testing at multiple scales
</performance_patterns>

<user_story_format>
**User Story Format**

For linking requirements to user needs:

**Template:**
As a {role},
I want {feature/capability},
So that {benefit/value}.

**Acceptance Criteria:**
Given {precondition},
When {action},
Then {expected result}.

**Example:**
As a CLI user,
I want to see progress during long operations,
So that I know the tool hasn't frozen.

Given a file export taking > 2 seconds,
When export begins,
Then a progress indicator appears updating at least every second.
</user_story_format>
