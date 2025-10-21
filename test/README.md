# PowerShell Utilities Test Suite

This directory contains comprehensive tests for the PowerShell utility scripts.

## Test Structure

```
test/
├── run_all_tests.ps1     # Main test runner
├── run_test.ps1          # Individual test runner
├── README.md             # This file
├── set_env/
│   ├── test_set_env.ps1  # Tests for set_env.ps1
│   └── .dev_env.json     # Test configuration
├── init_env/
│   └── test_init_env.ps1 # Tests for init_env.ps1
├── run/
│   ├── test_run.ps1      # Tests for run.ps1
│   └── .dev_env.json     # Test configuration
└── show_env/
    ├── test_show_env.ps1 # Tests for show_env.ps1
    └── .dev_env.json     # Test configuration
```

## Running Tests

### Run All Tests
```powershell
# Run all test suites
.\test\run_all_tests.ps1

# Run with verbose output
.\test\run_all_tests.ps1 -Verbose

# Run specific test suites
.\test\run_all_tests.ps1 -TestSuite @("set_env", "run")

# Stop on first failure
.\test\run_all_tests.ps1 -StopOnFailure
```

### Run Individual Test Suite
```powershell
# Run a specific test suite
.\test\run_test.ps1 -TestSuite set_env

# Run with verbose output
.\test\run_test.ps1 -TestSuite run -Verbose
```

### Run Tests Directly
```powershell
# Navigate to test directory and run directly
cd .\test\set_env\
.\test_set_env.ps1 -Verbose
```

## Test Coverage

### set_env.ps1 Tests
- ✅ Default temp_env loading
- ✅ Numbered temp_env loading (temp_env_1, temp_env_2)
- ✅ Non-existent temp_env handling
- ✅ Environment variable validation

### init_env.ps1 Tests
- ✅ Initialize from template
- ✅ Existing file detection
- ✅ DEV_ENV_VARIABLES initialization
- ✅ Fallback to empty file
- ✅ Schema path resolution

### run.ps1 Tests
- ✅ List available commands
- ✅ Simple string commands
- ✅ Complex object commands
- ✅ Environment variable injection
- ✅ Working directory changes
- ✅ Non-existent command handling

### show_env.ps1 Tests
- ✅ Show all configuration
- ✅ Filter by exact property name
- ✅ Filter by partial match
- ✅ Multiple property matching
- ✅ No match handling
- ✅ Complex object display with proper indentation

## Test Features

- **Comprehensive Coverage**: Tests cover main functionality and edge cases
- **Isolated Environments**: Each test suite has its own .dev_env.json configuration
- **Verbose Output**: Optional detailed output for debugging
- **Error Handling**: Proper cleanup and error reporting
- **Result Summary**: Clear pass/fail reporting with statistics

## Adding New Tests

1. Create a new test directory: `test/script_name/`
2. Add test configuration: `.dev_env.json`
3. Create test script: `test_script_name.ps1`
4. Update `run_all_tests.ps1` to include new test suite
5. Follow existing test patterns for consistency

## Test Configuration Files

Each test directory contains a `.dev_env.json` file with test-specific configuration:
- **Schema Reference**: Points to the main schema file
- **Test Data**: Relevant configuration for testing specific functionality
- **Isolation**: Independent configurations prevent test interference