package main

import (
	"os"
	"path/filepath"
)

// getEnvOrUseDefault returns environment variable value if explicitly set, otherwise returns default
func getEnvOrUseDefault(envVar, defaultVal string) string {
	if val := os.Getenv(envVar); val != "" {
		return val
	}
	return defaultVal
}

// expandHomeDir expands ~ to user home directory
func expandHomeDir(path string) string {
	if path[:2] == "~/" {
		homeDir, _ := os.UserHomeDir()
		return filepath.Join(homeDir, path[2:])
	}
	return path
}

// Paths and Directories
var (
	InstallDir = expandHomeDir(getEnvOrUseDefault("CMDY_INSTALL_DIR", "~/.local/bin"))
	ConfigDir  = expandHomeDir(getEnvOrUseDefault("CMDY_CONFIG_DIR", "~/.config/cmdy"))
	
	// Script directories (relative to ConfigDir)
	ScriptsDirExamples = getEnvOrUseDefault("CMDY_SCRIPTS_EXAMPLES", "scripts/examples")
	ScriptsDirUser     = getEnvOrUseDefault("CMDY_SCRIPTS_USER", "scripts/user")
	ScriptsDirLegacy   = getEnvOrUseDefault("CMDY_SCRIPTS_LEGACY", "scripts")
	
	// Filenames
	ConfigFileName    = getEnvOrUseDefault("CMDY_CONFIG_FILE", "config.yaml")
	ConfigFileBackup  = getEnvOrUseDefault("CMDY_CONFIG_BACKUP", "config.yaml.new")
	MainGoFileName    = getEnvOrUseDefault("CMDY_MAIN_FILE", "main.go")
	BinaryName        = getEnvOrUseDefault("CMDY_BINARY_NAME", "cmdy")
	BinaryNameTemp    = getEnvOrUseDefault("CMDY_BINARY_TEMP", "cmdy.bin")
)

// URLs and External Resources
var (
	RepoURL       = getEnvOrUseDefault("CMDY_REPO_URL", "https://github.com/jdpierce21/cmdy")
	RepoRawURL    = getEnvOrUseDefault("CMDY_REPO_RAW_URL", "https://raw.githubusercontent.com/jdpierce21/cmdy/master")
	InstallScript = getEnvOrUseDefault("CMDY_INSTALL_SCRIPT", "https://raw.githubusercontent.com/jdpierce21/cmdy/master/install.sh")
	GoInstallURL  = getEnvOrUseDefault("CMDY_GO_INSTALL_URL", "https://golang.org/doc/install")
	FzfInstallURL = getEnvOrUseDefault("CMDY_FZF_INSTALL_URL", "https://github.com/junegunn/fzf#installation")
)

// Git Settings
var (
	GitBranch = getEnvOrUseDefault("CMDY_GIT_BRANCH", "master")
	GitRemote = getEnvOrUseDefault("CMDY_GIT_REMOTE", "origin")
)

// Commands and Options
var (
	FzfCommand = getEnvOrUseDefault("CMDY_FZF_COMMAND", "fzf --header=Select an option: --height=~50% --layout=reverse")
	FzfHeader  = getEnvOrUseDefault("CMDY_FZF_HEADER", "Select an option:")
	
	GoBuildFlags = getEnvOrUseDefault("CMDY_GO_BUILD_FLAGS", "-ldflags=-s -w")
	ShellCommand = getEnvOrUseDefault("CMDY_SHELL_COMMAND", "sh -c")
)

// Colors (ANSI codes)
var (
	ColorRed    = getEnvOrUseDefault("CMDY_COLOR_RED", "\033[0;31m")
	ColorGreen  = getEnvOrUseDefault("CMDY_COLOR_GREEN", "\033[0;32m")
	ColorYellow = getEnvOrUseDefault("CMDY_COLOR_YELLOW", "\033[1;33m")
	ColorBlue   = getEnvOrUseDefault("CMDY_COLOR_BLUE", "\033[0;34m")
	ColorReset  = getEnvOrUseDefault("CMDY_COLOR_RESET", "\033[0m")
)

// UI Text and Messages
var (
	AppTitle         = getEnvOrUseDefault("CMDY_APP_TITLE", "cmdy - Modern CLI Command Assistant")
	InstallMessage   = getEnvOrUseDefault("CMDY_INSTALL_MESSAGE", "🚀 Installing cmdy")
	UpdateMessage    = getEnvOrUseDefault("CMDY_UPDATE_MESSAGE", "🔄 Updating cmdy")
	SuccessInstall   = getEnvOrUseDefault("CMDY_SUCCESS_INSTALL", "✓ Installed")
	SuccessUpdate    = getEnvOrUseDefault("CMDY_SUCCESS_UPDATE", "✓ Updated")
	SuccessComplete  = getEnvOrUseDefault("CMDY_SUCCESS_COMPLETE", "✓ Complete")
	
	// Script prefixes
	PrefixExample = getEnvOrUseDefault("CMDY_PREFIX_EXAMPLE", "[example] ")
	PrefixUser    = getEnvOrUseDefault("CMDY_PREFIX_USER", "[user] ")
	
	// Default commit message
	DefaultCommitMsg = getEnvOrUseDefault("CMDY_DEFAULT_COMMIT", "Update cmdy")
	
	// Error messages
	ErrorGoNotFound     = getEnvOrUseDefault("CMDY_ERROR_GO", "Error: Go compiler not found")
	ErrorMainNotFound   = getEnvOrUseDefault("CMDY_ERROR_MAIN", "Error: main.go not found")
	ErrorNoScripts      = getEnvOrUseDefault("CMDY_ERROR_NO_SCRIPTS", "No executable scripts found in scripts/ directories")
	ErrorNoOptions      = getEnvOrUseDefault("CMDY_ERROR_NO_OPTIONS", "Error: No menu options available")
	HelpAddScripts      = getEnvOrUseDefault("CMDY_HELP_ADD_SCRIPTS", "Add scripts to scripts/user/ or scripts/examples/")
	VersionUnknown      = getEnvOrUseDefault("CMDY_VERSION_UNKNOWN", "Version: unknown (not in git repo)")
)

// ASCII Logo
var LogoLines = []string{
	getEnvOrUseDefault("CMDY_LOGO_LINE1", "  ██████╗ ███╗   ███╗ ██████╗  ██╗   ██╗"),
	getEnvOrUseDefault("CMDY_LOGO_LINE2", " ██╔════╝ ████╗ ████║ ██╔══██╗ ╚██╗ ██╔╝"),
	getEnvOrUseDefault("CMDY_LOGO_LINE3", " ██║      ██╔████╔██║ ██║  ██║  ╚████╔╝ "),
	getEnvOrUseDefault("CMDY_LOGO_LINE4", " ██║      ██║╚██╔╝██║ ██║  ██║   ╚██╔╝  "),
	getEnvOrUseDefault("CMDY_LOGO_LINE5", " ╚██████╗ ██║ ╚═╝ ██║ ██████╔╝    ██║   "),
	getEnvOrUseDefault("CMDY_LOGO_LINE6", "  ╚═════╝ ╚═╝     ╚═╝ ╚═════╝     ╚═╝   "),
}

// File Permissions
const (
	PermExecutable = 0755
	PermDirectory  = 0755
	ExecuteBitMask = 0111
)

// OS Mappings
var OSMappings = map[string]string{
	"darwin": "mac",
}

// Search Locations for cmdy source (relative to home directory)
var SourceSearchLocations = []string{
	getEnvOrUseDefault("CMDY_SEARCH_LOC1", "cmdy"),
	getEnvOrUseDefault("CMDY_SEARCH_LOC2", "projects/cmdy"),
	getEnvOrUseDefault("CMDY_SEARCH_LOC3", "src/cmdy"),
	getEnvOrUseDefault("CMDY_SEARCH_LOC4", "dev/cmdy"),
	getEnvOrUseDefault("CMDY_SEARCH_LOC5", "code/cmdy"),
	getEnvOrUseDefault("CMDY_SEARCH_LOC6", "scripts/cmdy"),
}

// Editor fallback list
var EditorCandidates = []string{
	"nano", "vi", "vim", "emacs", "code", "notepad",
}

// Helper function to get full install path
func GetInstallPath() string {
	return filepath.Join(InstallDir, BinaryName)
}

// Helper function to get full config path
func GetConfigPath() string {
	return filepath.Join(ConfigDir, ConfigFileName)
}

// Helper function to get script directories with full paths
func GetScriptDirs() []string {
	return []string{
		filepath.Join(ConfigDir, ScriptsDirExamples),
		filepath.Join(ConfigDir, ScriptsDirUser),
		filepath.Join(ConfigDir, ScriptsDirLegacy),
	}
}

// Helper function to show logo
func ShowLogo() {
	println(ColorBlue)
	for _, line := range LogoLines {
		println(line)
	}
	println(ColorReset)
}