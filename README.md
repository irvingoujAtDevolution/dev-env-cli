# PowerShell Development Utility Toolkit

A comprehensive PowerShell-based toolkit for development environment management, quick command execution, and gateway operations.

## Table of Contents

- [Quick Start](#quick-start)
- [Core Scripts](#core-scripts)
  - [init_env.ps1](#init_envps1)
  - [add_env.ps1](#add_envps1)
  - [set_env.ps1](#set_envps1)
  - [run.ps1](#runps1)
- [Other Useful Scripts](#other-useful-scripts)
- [Configuration File Structure](#configuration-file-structure)
- [Testing](#testing)

---

## Quick Start

### 1. Initialize Your Environment

Create a `.dev_env.json` configuration file in your project directory:

```powershell
.\init_env.ps1
```

This creates a new configuration file with the template structure. If `$env:DEV_ENV_VARIABLES` is set, it will use that file as the source.

### 2. Add Environment Variables

Add environment variables to your configuration:

```powershell
# Add to default profile (temp_env)
.\add_env.ps1 0 API_KEY=my-secret-key
.\add_env.ps1 0 DATABASE_URL=postgresql://localhost:5432/mydb

# Add to numbered profiles (temp_env_1, temp_env_2, etc.)
.\add_env.ps1 1 STAGING_API_KEY=staging-key
.\add_env.ps1 2 PROD_API_KEY=prod-key
```

### 3. Load Environment Variables

Load environment variables into your current PowerShell session:

```powershell
# Load default profile (temp_env)
.\set_env.ps1

# Load numbered profile (temp_env_1)
.\set_env.ps1 -number 1
```

### 4. Add Quick Commands

Edit your `.dev_env.json` manually or use a text editor:

```powershell
.\edit_env.ps1
```

Add commands to the `quick_command` section:

```json
{
  "quick_command": {
    "dev": "npm run dev",
    "test": "npm test",
    "build": {
      "cwd": "./src",
      "command": "dotnet",
      "args": ["build", "-c", "Release"],
      "env": [{"BUILD_ENV": "production"}]
    }
  }
}
```

### 5. Run Quick Commands

Execute your predefined commands:

```powershell
# List all available commands
.\run.ps1

# Run a specific command
.\run.ps1 dev
.\run.ps1 test
.\run.ps1 build
```

---

## Core Scripts

### init_env.ps1

**Purpose**: Initialize a new `.dev_env.json` configuration file in the current directory.

**Usage**:
```powershell
.\init_env.ps1
```

**What It Does**:
1. Creates a new `.dev_env.json` file in the current directory
2. If `$env:DEV_ENV_VARIABLES` is set and points to a valid JSON file, copies content from there
3. Otherwise, copies from the template at `./template/.dev_env.json`
4. If neither exists, creates an empty JSON object `{}`

**Example**:
```powershell
# Navigate to your project directory
cd C:\Projects\MyApp

# Initialize configuration
.\init_env.ps1
# Output: Created .dev_env.json at C:\Projects\MyApp\.dev_env.json
```

**Related Scripts**:
- `init_from_template.ps1` - Initialize configuration at a specific path with `-Force` option

---

### add_env.ps1

**Purpose**: Add or update environment variables in your `.dev_env.json` configuration.

**Usage**:
```powershell
.\add_env.ps1 [PROFILE] [NAME]=[VALUE]
```

**Parameters**:
- `PROFILE`: The profile name (`temp_env`, `temp_env_1`, etc.) or numeric shorthand (`0` for `temp_env`, `1` for `temp_env_1`)
- `NAME=VALUE`: The environment variable assignment

**Examples**:

```powershell
# Add to default profile (temp_env)
.\add_env.ps1 0 API_KEY=abc123xyz
.\add_env.ps1 temp_env DATABASE_URL=postgresql://localhost:5432/devdb

# Add to numbered profiles
.\add_env.ps1 1 REDIS_URL=redis://localhost:6379
.\add_env.ps1 temp_env_2 STAGING_URL=https://staging.example.com

# Update existing variable
.\add_env.ps1 0 API_KEY=new-key-value
# Output: Updating temp_env.API_KEY = new-key-value

# Values with special characters
.\add_env.ps1 0 CONNECTION_STRING="Server=localhost;Database=mydb;User=admin;Password=p@ssw0rd"
```

**Features**:
- Creates the profile automatically if it doesn't exist
- Updates the variable if it already exists
- Prevents editing the template file directly
- Searches up the directory tree for `.dev_env.json`
- Validates JSON structure

**Notes**:
- Variables are only added to the configuration file, not set in the current session
- Use `set_env.ps1` to load variables into your session
- The script will not allow you to modify the template file

---

### set_env.ps1

**Purpose**: Load environment variables from `.dev_env.json` into your current PowerShell session.

**Usage**:
```powershell
.\set_env.ps1              # Load temp_env
.\set_env.ps1 -number 1    # Load temp_env_1
.\set_env.ps1 -number 2    # Load temp_env_2
```

**Parameters**:
- `-number` (optional): The profile number to load. Omit for default `temp_env`.

**Examples**:

```powershell
# Load default profile
.\set_env.ps1
# Output:
# Found .dev_env.json file at C:\Projects\MyApp\.dev_env.json
# Setting environment variables for C:\Projects\MyApp\.dev_env.json
# Setting environment variable API_KEY to abc123xyz
# Setting environment variable DATABASE_URL to postgresql://localhost:5432/devdb

# Verify variables are set
echo $env:API_KEY
# Output: abc123xyz

# Load a different profile
.\set_env.ps1 -number 1
# Output: Setting environment variable REDIS_URL to redis://localhost:6379

# Use in your scripts
.\set_env.ps1
npm run dev  # Now has access to all environment variables
```

**How It Works**:
1. Searches up the directory tree for all `.dev_env.json` files
2. Processes each file found (from current directory upward)
3. Loads all string variables from the specified profile (`temp_env` or `temp_env_N`)
4. Sets them at the Process scope (current session only)

**Features**:
- Recursive search finds all config files in parent directories
- Variables are only set for the current PowerShell session
- Non-string values are ignored (only string variables are loaded)
- Multiple config files can be processed (child configs can override parent configs)

**Use Cases**:

```powershell
# Development workflow
.\set_env.ps1          # Load development variables
dotnet run             # Run with dev environment

# Staging environment
.\set_env.ps1 -number 1
dotnet run             # Run with staging environment

# Production environment
.\set_env.ps1 -number 2
dotnet run             # Run with production environment

# Run tests with specific environment
.\set_env.ps1 -number 3
npm test
```

---

### run.ps1

**Purpose**: Execute predefined quick commands from your `.dev_env.json` configuration.

**Usage**:
```powershell
.\run.ps1               # List all available commands
.\run.ps1 [COMMAND]     # Execute a specific command
.\run.ps1 [COMMAND] [ADDITIONAL_ARGS]  # Execute with extra arguments
```

**Examples**:

```powershell
# List all available commands
.\run.ps1
# Output:
# Available quick commands:
#   dev
#   test
#   build
#   deploy

# Run a simple command
.\run.ps1 dev
# Executes: npm run dev

# Run a command with additional arguments
.\run.ps1 test --verbose
# Executes: npm test --verbose
```

**Command Formats**:

#### Simple String Commands

```json
{
  "quick_command": {
    "dev": "npm run dev",
    "test": "npm test",
    "hello": "echo 'Hello World'"
  }
}
```

Usage:
```powershell
.\run.ps1 dev    # Runs: npm run dev
.\run.ps1 test   # Runs: npm test
.\run.ps1 hello  # Runs: echo 'Hello World'
```

#### Advanced Object Commands

```json
{
  "quick_command": {
    "build": {
      "cwd": "./src",
      "command": "dotnet",
      "args": ["build", "-c", "Release"],
      "env": [{"BUILD_ENV": "production"}]
    }
  }
}
```

**Object Properties**:
- `cwd` (optional): Working directory to run the command in
- `command`: The executable/command to run
- `args` (optional): Array of arguments to pass to the command
- `env` (optional): Array of environment variable objects to set for this command

Usage:
```powershell
.\run.ps1 build
# Changes to ./src directory
# Sets BUILD_ENV=production
# Runs: dotnet build -c Release
# Returns to original directory
```

**Complex Examples**:

```json
{
  "quick_command": {
    "db-migrate": {
      "cwd": "./database",
      "command": "npx",
      "args": ["prisma", "migrate", "dev"],
      "env": [
        {"DATABASE_URL": "postgresql://localhost:5432/devdb"},
        {"PRISMA_HIDE_UPDATE_MESSAGE": "true"}
      ]
    },
    "docker-up": "docker-compose up -d",
    "docker-down": "docker-compose down",
    "clean": {
      "command": "powershell",
      "args": ["-Command", "Remove-Item -Recurse -Force bin,obj"]
    }
  }
}
```

**Features**:
- Preserves original working directory after command execution
- Supports environment variable injection per command
- Appends additional CLI arguments to the command
- Lists all available commands when called without arguments

**Real-World Workflow**:

```powershell
# Setup your environment and run development server
.\set_env.ps1
.\run.ps1 docker-up
.\run.ps1 db-migrate
.\run.ps1 dev

# Run tests in staging environment
.\set_env.ps1 -number 1
.\run.ps1 test

# Build and deploy to production
.\set_env.ps1 -number 2
.\run.ps1 build
.\run.ps1 deploy
```

---

## Other Useful Scripts

### show_env.ps1

Display configuration values from `.dev_env.json`:

```powershell
.\show_env.ps1              # Show entire configuration
.\show_env.ps1 -Name ssh    # Show properties matching "ssh"
```

### edit_env.ps1

Open configuration file in your default editor (VS Code by default):

```powershell
.\edit_env.ps1
```

### copy_env.ps1

Search for and copy environment variable values to clipboard:

```powershell
.\copy_env.ps1 API_KEY
```

### to.ps1

Quick navigation to saved locations defined in `quick_locations`:

```powershell
.\to.ps1           # List available locations
.\to.ps1 home      # Navigate to saved 'home' location
```

### token_gen.ps1

Generate authentication tokens for Devolutions Gateway:

```powershell
.\token_gen.ps1              # Generate and display tokens
.\token_gen.ps1 copy token   # Copy connection token to clipboard
.\token_gen.ps1 copy krb     # Copy Kerberos URL to clipboard
```

### d.ps1

.NET development workflow commands:

```powershell
.\d.ps1 build      # Build project
.\d.ps1 pack       # Create NuGet package
.\d.ps1 push       # Push to local NuGet server
.\d.ps1 cc         # Clear NuGet cache
.\d.ps1 rm-bin     # Remove build artifacts
```

---

## Configuration File Structure

The `.dev_env.json` file structure:

```json
{
  "$schema": "./template/.dev_env.schema.json",

  "quick_command": {
    "dev": "npm run dev",
    "build": {
      "cwd": "./src",
      "command": "dotnet",
      "args": ["build", "-c", "Release"],
      "env": [{"BUILD_ENV": "production"}]
    }
  },

  "temp_env": {
    "API_KEY": "development-api-key",
    "DATABASE_URL": "postgresql://localhost:5432/devdb",
    "DEBUG_MODE": "true"
  },

  "temp_env_1": {
    "API_KEY": "staging-api-key",
    "DATABASE_URL": "postgresql://staging-db:5432/stagingdb",
    "DEBUG_MODE": "false"
  },

  "temp_env_2": {
    "API_KEY": "production-api-key",
    "DATABASE_URL": "postgresql://prod-db:5432/proddb",
    "DEBUG_MODE": "false"
  },

  "quick_locations": [
    { "name": "home", "location": "C:\\Users\\username" },
    { "name": "code", "location": "C:\\Projects" }
  ],

  "private_key_file": "C:\\ProgramData\\Devolutions\\Gateway\\provisioner.key",
  "gateway_websocket_url": "ws://localhost:7171",
  "ssh_destination_host": "primary:22",
  "target": "ssh"
}
```

### Schema Validation

The toolkit includes a JSON schema file (`template/.dev_env.schema.json`) that provides:
- IntelliSense support in VS Code
- Validation of configuration structure
- Documentation for all properties

---

## Testing

The toolkit includes a comprehensive test suite:

```powershell
# Run all tests
cd test
.\run_all_tests.ps1

# Run specific test suite
.\run_test.ps1 -TestSuite set_env

# Run with verbose output
.\run_all_tests.ps1 -Verbose

# Stop on first failure
.\run_all_tests.ps1 -StopOnFailure
```

Test coverage includes:
- Environment variable management
- Configuration initialization
- Quick command execution
- Directory navigation
- Configuration filtering

---

## Common Workflows

### Project Setup Workflow

```powershell
# 1. Navigate to your project
cd C:\Projects\MyNewApp

# 2. Initialize configuration
.\init_env.ps1

# 3. Add environment variables
.\add_env.ps1 0 API_KEY=dev-key
.\add_env.ps1 0 DATABASE_URL=postgresql://localhost:5432/myapp
.\add_env.ps1 0 REDIS_URL=redis://localhost:6379

# 4. Edit config to add quick commands
.\edit_env.ps1
# Add your commands to "quick_command" section

# 5. Load environment and run
.\set_env.ps1
.\run.ps1 dev
```

### Multi-Environment Development

```powershell
# Setup different environments
.\add_env.ps1 0 API_URL=http://localhost:3000
.\add_env.ps1 1 API_URL=https://staging.example.com
.\add_env.ps1 2 API_URL=https://api.example.com

# Switch between environments
.\set_env.ps1          # Development
.\set_env.ps1 -number 1  # Staging
.\set_env.ps1 -number 2  # Production
```

### Microservices Development

```powershell
# Parent directory .dev_env.json (shared config)
{
  "temp_env": {
    "SHARED_SECRET": "common-secret",
    "LOG_LEVEL": "debug"
  },
  "quick_command": {
    "start-all": "docker-compose up -d"
  }
}

# Service-specific .dev_env.json (overrides parent)
{
  "temp_env": {
    "SERVICE_NAME": "auth-service",
    "PORT": "3001"
  },
  "quick_command": {
    "dev": "npm run dev"
  }
}

# set_env.ps1 loads both configs (child overrides parent)
```

---

## Tips and Best practices

1. **Use numbered profiles for different environments**:
   - `temp_env` (or `0`) - Development
   - `temp_env_1` (or `1`) - Staging
   - `temp_env_2` (or `2`) - Production

2. **Leverage the hierarchical config system**:
   - Place shared configuration in parent directories
   - Override specific values in project directories

3. **Use quick commands for common workflows**:
   - Reduces typing for frequently used commands
   - Documents common operations for team members
   - Ensures consistent command execution

4. **Never commit `.dev_env.json` with secrets**:
   - The `.gitignore` already excludes it
   - Use `$env:DEV_ENV_VARIABLES` for team templates

5. **Combine scripts for powerful workflows**:
   ```powershell
   # Load environment and run command in one go
   .\set_env.ps1 -number 1; .\run.ps1 deploy
   ```

---

## Dependencies

- **PowerShell 5.1+** (required)
- **Devolutions Gateway** (for token generation cmdlets)
- **.NET SDK** (for `d.ps1` operations)
- **Rust/Cargo** (for `gateway_gen.ps1`)
- **Visual Studio 2022** (optional, for `vs.ps1`)

---

## License

This toolkit is designed for internal development use. Includes MIT-licensed components (sudo.ps1).

---

## Contributing

When adding new scripts:
1. Follow the existing naming conventions
2. Use `get_env_path.ps1` for configuration file discovery
3. Add test coverage in the `test/` directory
4. Update this README with usage examples
