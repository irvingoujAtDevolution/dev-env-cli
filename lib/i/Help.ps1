# Help.ps1 - Comprehensive help documentation

function Show-MainHelp {
    Write-Host ""
    Write-Host "  i - Development Environment CLI" -ForegroundColor Cyan
    Write-Host "  ================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  A unified tool for managing development commands and environment" -ForegroundColor Gray
    Write-Host "  variables across projects with automatic config inheritance." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host "    i <command> [options]"
    Write-Host ""
    Write-Host "  COMMANDS" -ForegroundColor Yellow
    Write-Host "    run <cmd> [args]     Run a command defined in config"
    Write-Host "    <cmd> [args]         Shortcut for 'i run <cmd>'"
    Write-Host "    set env [profile]    Set environment variables from a profile"
    Write-Host "    list cmd             List available commands"
    Write-Host "    list env             List available env profiles"
    Write-Host "    add cmd <n> <run>    Add a new command"
    Write-Host "    add env <p> K=V      Add/update an env profile"
    Write-Host "    init                 Initialize .dev_env.json in current dir"
    Write-Host "    migrate              Migrate v1 config to v2 format"
    Write-Host "    help                 Show this help"
    Write-Host ""
    Write-Host "  OPTIONS" -ForegroundColor Yellow
    Write-Host "    -h, --help           Show help for any command"
    Write-Host ""
    Write-Host "  EXAMPLES" -ForegroundColor Yellow
    Write-Host "    i build                      Run the 'build' command" -ForegroundColor Gray
    Write-Host "    i build --release            Run 'build' with extra args" -ForegroundColor Gray
    Write-Host "    i set env dev                Load 'dev' env profile" -ForegroundColor Gray
    Write-Host "    i add cmd test 'npm test'    Add a test command" -ForegroundColor Gray
    Write-Host "    i list cmd                   Show all available commands" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  CONFIG INHERITANCE" -ForegroundColor Yellow
    Write-Host "    Configs are merged from parent directories. Child configs override parent." -ForegroundColor Gray
    Write-Host "    Example: ~/project/.dev_env.json + ~/project/app/.dev_env.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  MORE HELP" -ForegroundColor Yellow
    Write-Host "    i run --help         Help for running commands"
    Write-Host "    i add --help         Help for adding commands/env"
    Write-Host "    i set --help         Help for setting env variables"
    Write-Host "    i list --help        Help for listing commands/env"
    Write-Host ""
}

function Show-RunHelp {
    Write-Host ""
    Write-Host "  i run - Run Commands" -ForegroundColor Cyan
    Write-Host "  ====================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Execute commands defined in your .dev_env.json config files." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host "    i run <command> [extra-args...]"
    Write-Host "    i <command> [extra-args...]        (shortcut)"
    Write-Host ""
    Write-Host "  ARGUMENTS" -ForegroundColor Yellow
    Write-Host "    <command>        Name of the command to run"
    Write-Host "    [extra-args]     Additional arguments passed to the command"
    Write-Host ""
    Write-Host "  EXAMPLES" -ForegroundColor Yellow
    Write-Host "    i run build                  Run the 'build' command" -ForegroundColor Gray
    Write-Host "    i build                      Same as above (shortcut)" -ForegroundColor Gray
    Write-Host "    i build --release            Pass '--release' to build command" -ForegroundColor Gray
    Write-Host "    i test --verbose --coverage  Pass multiple args" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  COMMAND TYPES" -ForegroundColor Yellow
    Write-Host "    Commands can be defined as:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    String command:" -ForegroundColor White
    Write-Host '      "build": "dotnet build"' -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Object command (with options):" -ForegroundColor White
    Write-Host '      "dev": {' -ForegroundColor DarkGray
    Write-Host '        "run": "npm start",' -ForegroundColor DarkGray
    Write-Host '        "cwd": "./frontend",' -ForegroundColor DarkGray
    Write-Host '        "env": "dev"' -ForegroundColor DarkGray
    Write-Host '      }' -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ENV RESOLUTION" -ForegroundColor Yellow
    Write-Host "    The 'env' field can be:" -ForegroundColor Gray
    Write-Host "      - Profile name:      " -NoNewline; Write-Host '"env": "dev"' -ForegroundColor DarkGray
    Write-Host "      - Multiple profiles: " -NoNewline; Write-Host '"env": ["default", "dev"]' -ForegroundColor DarkGray
    Write-Host "      - Inline vars:       " -NoNewline; Write-Host '"env": {"KEY": "value"}' -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  SEE ALSO" -ForegroundColor Yellow
    Write-Host "    i list cmd           List available commands"
    Write-Host "    i add cmd --help     Help for adding commands"
    Write-Host ""
}

function Show-SetHelp {
    Write-Host ""
    Write-Host "  i set - Set Environment Variables" -ForegroundColor Cyan
    Write-Host "  ==================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Load environment variables from a profile in your config." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host "    i set env [profile]"
    Write-Host ""
    Write-Host "  ARGUMENTS" -ForegroundColor Yellow
    Write-Host "    [profile]        Name of the env profile (default: 'default')"
    Write-Host ""
    Write-Host "  EXAMPLES" -ForegroundColor Yellow
    Write-Host "    i set env                    Load 'default' profile" -ForegroundColor Gray
    Write-Host "    i set env dev                Load 'dev' profile" -ForegroundColor Gray
    Write-Host "    i set env prod               Load 'prod' profile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  CONFIG EXAMPLE" -ForegroundColor Yellow
    Write-Host '    "env": {' -ForegroundColor DarkGray
    Write-Host '      "default": {' -ForegroundColor DarkGray
    Write-Host '        "API_URL": "http://localhost:8080"' -ForegroundColor DarkGray
    Write-Host '      },' -ForegroundColor DarkGray
    Write-Host '      "dev": {' -ForegroundColor DarkGray
    Write-Host '        "API_URL": "http://localhost:8080",' -ForegroundColor DarkGray
    Write-Host '        "DEBUG": "true"' -ForegroundColor DarkGray
    Write-Host '      },' -ForegroundColor DarkGray
    Write-Host '      "prod": {' -ForegroundColor DarkGray
    Write-Host '        "API_URL": "https://api.example.com"' -ForegroundColor DarkGray
    Write-Host '      }' -ForegroundColor DarkGray
    Write-Host '    }' -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  INHERITANCE" -ForegroundColor Yellow
    Write-Host "    Profiles are merged from parent configs. Child profiles override parent." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  SEE ALSO" -ForegroundColor Yellow
    Write-Host "    i list env           List available env profiles"
    Write-Host "    i add env --help     Help for adding env profiles"
    Write-Host ""
}

function Show-ListHelp {
    Write-Host ""
    Write-Host "  i list - List Commands & Env Profiles" -ForegroundColor Cyan
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Display available commands or environment profiles." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host "    i list cmd           List all commands"
    Write-Host "    i list env           List all env profiles"
    Write-Host ""
    Write-Host "  ALIASES" -ForegroundColor Yellow
    Write-Host "    i list command       Same as 'i list cmd'"
    Write-Host "    i list commands      Same as 'i list cmd'"
    Write-Host ""
    Write-Host "  OUTPUT" -ForegroundColor Yellow
    Write-Host "    Shows merged results from all .dev_env.json files in the" -ForegroundColor Gray
    Write-Host "    directory hierarchy, with sources listed at the bottom." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  EXAMPLES" -ForegroundColor Yellow
    Write-Host "    i list cmd           Show all commands with their definitions" -ForegroundColor Gray
    Write-Host "    i list env           Show all env profiles with their variables" -ForegroundColor Gray
    Write-Host ""
}

function Show-AddHelp {
    Write-Host ""
    Write-Host "  i add - Add Commands & Env Profiles" -ForegroundColor Cyan
    Write-Host "  ====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Add or update commands and env profiles in your config." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host "    i add cmd <name> <run> [options]"
    Write-Host "    i add env <profile> KEY=VALUE ..."
    Write-Host ""
    Write-Host "  For detailed help:" -ForegroundColor Gray
    Write-Host "    i add cmd --help     Help for adding commands"
    Write-Host "    i add env --help     Help for adding env profiles"
    Write-Host ""
}

function Show-AddCmdHelp {
    Write-Host ""
    Write-Host "  i add cmd - Add Commands" -ForegroundColor Cyan
    Write-Host "  ========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Add a new command to your .dev_env.json config." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host '    i add cmd <name> "<run>" [cwd=<path>] [env=<value>]'
    Write-Host ""
    Write-Host "  ARGUMENTS" -ForegroundColor Yellow
    Write-Host "    <name>           Command name (e.g., 'build', 'dev', 'test')"
    Write-Host "    <run>            The command to execute (quoted if has spaces)"
    Write-Host ""
    Write-Host "  OPTIONS" -ForegroundColor Yellow
    Write-Host "    cwd=<path>       Working directory for the command"
    Write-Host "    env=<value>      Environment (see ENV VALUES below)"
    Write-Host ""
    Write-Host "  ENV VALUES" -ForegroundColor Yellow
    Write-Host "    Profile reference:" -ForegroundColor White
    Write-Host "      env=dev                        Use 'dev' profile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    Multiple profiles:" -ForegroundColor White
    Write-Host "      env=default,dev                Merge profiles (dev overrides)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    Inline variables:" -ForegroundColor White
    Write-Host "      env=KEY=value                  Single variable" -ForegroundColor Gray
    Write-Host "      env=KEY1=val1,KEY2=val2        Multiple variables" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  EXAMPLES" -ForegroundColor Yellow
    Write-Host "    Simple command:" -ForegroundColor White
    Write-Host '      i add cmd build "dotnet build"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "    With working directory:" -ForegroundColor White
    Write-Host '      i add cmd dev "npm start" cwd=./frontend' -ForegroundColor Gray
    Write-Host ""
    Write-Host "    With env profile:" -ForegroundColor White
    Write-Host '      i add cmd serve "npm start" env=dev' -ForegroundColor Gray
    Write-Host ""
    Write-Host "    With inline env vars:" -ForegroundColor White
    Write-Host '      i add cmd dev "npm start" "env=NODE_ENV=development,PORT=3000"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "    Full example:" -ForegroundColor White
    Write-Host '      i add cmd dev "npm run dev" cwd=./app env=dev' -ForegroundColor Gray
    Write-Host ""
    Write-Host "  NOTES" -ForegroundColor Yellow
    Write-Host "    - Creates .dev_env.json if it doesn't exist" -ForegroundColor Gray
    Write-Host "    - Overwrites existing command with same name" -ForegroundColor Gray
    Write-Host "    - Profile references are validated (must exist)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  SEE ALSO" -ForegroundColor Yellow
    Write-Host "    i add env --help     Help for adding env profiles"
    Write-Host "    i list cmd           List existing commands"
    Write-Host ""
}

function Show-AddEnvHelp {
    Write-Host ""
    Write-Host "  i add env - Add Env Profiles" -ForegroundColor Cyan
    Write-Host "  =============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Add or update an environment profile in your config." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host '    i add env <profile> "KEY=VALUE" ...'
    Write-Host ""
    Write-Host "  ARGUMENTS" -ForegroundColor Yellow
    Write-Host "    <profile>        Profile name (e.g., 'default', 'dev', 'prod')"
    Write-Host "    KEY=VALUE        One or more environment variables"
    Write-Host ""
    Write-Host "  EXAMPLES" -ForegroundColor Yellow
    Write-Host "    Single variable:" -ForegroundColor White
    Write-Host '      i add env dev "DEBUG=true"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "    Multiple variables:" -ForegroundColor White
    Write-Host '      i add env prod "DEBUG=false" "LOG_LEVEL=error" "API_URL=https://api.prod.com"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "    Default profile:" -ForegroundColor White
    Write-Host '      i add env default "API_URL=http://localhost:8080"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "    Values with special characters:" -ForegroundColor White
    Write-Host '      i add env db "CONNECTION=Server=localhost;Port=5432;Database=mydb"' -ForegroundColor Gray
    Write-Host ""
    Write-Host "  BEHAVIOR" -ForegroundColor Yellow
    Write-Host "    - Creates profile if it doesn't exist" -ForegroundColor Gray
    Write-Host "    - Merges with existing profile (adds/updates vars)" -ForegroundColor Gray
    Write-Host "    - Creates .dev_env.json if it doesn't exist" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  SEE ALSO" -ForegroundColor Yellow
    Write-Host "    i add cmd --help     Help for adding commands"
    Write-Host "    i list env           List existing env profiles"
    Write-Host "    i set env --help     Help for setting env variables"
    Write-Host ""
}

function Show-InitHelp {
    Write-Host ""
    Write-Host "  i init - Initialize Config" -ForegroundColor Cyan
    Write-Host "  ==========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Create a new .dev_env.json file in the current directory." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host "    i init"
    Write-Host ""
    Write-Host "  BEHAVIOR" -ForegroundColor Yellow
    Write-Host "    - Creates .dev_env.json with v2 template structure" -ForegroundColor Gray
    Write-Host "    - Skips if file already exists" -ForegroundColor Gray
    Write-Host "    - Template includes example commands and env profiles" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  TEMPLATE STRUCTURE" -ForegroundColor Yellow
    Write-Host '    {' -ForegroundColor DarkGray
    Write-Host '      "commands": {' -ForegroundColor DarkGray
    Write-Host '        "build": "echo build command",' -ForegroundColor DarkGray
    Write-Host '        "dev": { "run": "echo dev", "env": "default" }' -ForegroundColor DarkGray
    Write-Host '      },' -ForegroundColor DarkGray
    Write-Host '      "env": {' -ForegroundColor DarkGray
    Write-Host '        "default": { "DEBUG": "false" },' -ForegroundColor DarkGray
    Write-Host '        "dev": { "DEBUG": "true" }' -ForegroundColor DarkGray
    Write-Host '      }' -ForegroundColor DarkGray
    Write-Host '    }' -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  SEE ALSO" -ForegroundColor Yellow
    Write-Host "    i migrate            Migrate v1 config to v2"
    Write-Host "    i add cmd --help     Add commands to config"
    Write-Host ""
}

function Show-MigrateHelp {
    Write-Host ""
    Write-Host "  i migrate - Migrate v1 Config" -ForegroundColor Cyan
    Write-Host "  ==============================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Convert a v1 .dev_env.json to the new v2 format." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  USAGE" -ForegroundColor Yellow
    Write-Host "    i migrate"
    Write-Host ""
    Write-Host "  TRANSFORMATIONS" -ForegroundColor Yellow
    Write-Host "    v1                          v2" -ForegroundColor White
    Write-Host "    --------------------------  --------------------------" -ForegroundColor DarkGray
    Write-Host "    quick_command         ->    commands" -ForegroundColor Gray
    Write-Host "    command + args        ->    run" -ForegroundColor Gray
    Write-Host '    env: [{"K":"V"}]      ->    env: {"K":"V"}' -ForegroundColor Gray
    Write-Host "    temp_env              ->    env.default" -ForegroundColor Gray
    Write-Host "    temp_env_1            ->    env.1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  EXAMPLE" -ForegroundColor Yellow
    Write-Host "    Before (v1):" -ForegroundColor White
    Write-Host '      {' -ForegroundColor DarkGray
    Write-Host '        "quick_command": {' -ForegroundColor DarkGray
    Write-Host '          "build": { "command": "dotnet", "args": ["build"] }' -ForegroundColor DarkGray
    Write-Host '        },' -ForegroundColor DarkGray
    Write-Host '        "temp_env": { "DEBUG": "true" }' -ForegroundColor DarkGray
    Write-Host '      }' -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    After (v2):" -ForegroundColor White
    Write-Host '      {' -ForegroundColor DarkGray
    Write-Host '        "commands": {' -ForegroundColor DarkGray
    Write-Host '          "build": { "run": "dotnet build" }' -ForegroundColor DarkGray
    Write-Host '        },' -ForegroundColor DarkGray
    Write-Host '        "env": {' -ForegroundColor DarkGray
    Write-Host '          "default": { "DEBUG": "true" }' -ForegroundColor DarkGray
    Write-Host '        }' -ForegroundColor DarkGray
    Write-Host '      }' -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  NOTES" -ForegroundColor Yellow
    Write-Host "    - Preserves unrelated fields (gateway, custom, etc.)" -ForegroundColor Gray
    Write-Host "    - Skips if already v2 format" -ForegroundColor Gray
    Write-Host "    - Backup recommended before migrating" -ForegroundColor Gray
    Write-Host ""
}

function Test-HelpFlag {
    param([string[]]$Arguments)
    if ($null -eq $Arguments) { return $false }
    return ($Arguments -contains "-h") -or
           ($Arguments -contains "--help") -or
           ($Arguments -contains "-help") -or
           ($Arguments -contains "help")
}
