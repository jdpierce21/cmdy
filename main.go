package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"gopkg.in/yaml.v3"
)

type MenuOption struct {
	Display  string            `yaml:"display"`
	Commands map[string]string `yaml:"commands"`
}


func runFzf(options []MenuOption) (string, error) {
	var b strings.Builder
	b.Grow(len(options) * 32) // Estimate capacity
	for i, option := range options {
		if i > 0 {
			b.WriteByte('\n')
		}
		b.WriteString(option.Display)
	}

	cmd := exec.Command("fzf", "--header=" + FzfHeader, "--height=~50%", "--layout=reverse")
	cmd.Stdin = strings.NewReader(b.String())
	cmd.Stderr = os.Stderr

	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func discoverScripts() []MenuOption {
	var discovered []MenuOption
	
	// Scan script directories
	dirs := GetScriptDirs()
	
	for _, scriptsDir := range dirs {
		scripts := scanScriptDirectory(scriptsDir)
		discovered = append(discovered, scripts...)
	}
	
	if len(discovered) == 0 {
		fmt.Println(ErrorNoScripts)
		fmt.Println(HelpAddScripts)
	}
	
	return discovered
}

func scanScriptDirectory(scriptsDir string) []MenuOption {
	var discovered []MenuOption
	
	files, err := os.ReadDir(scriptsDir)
	if err != nil {
		// Silent skip for missing directories (examples/ might not exist yet)
		return discovered
	}
	
	currentOS := runtime.GOOS
	if currentOS == "darwin" {
		currentOS = "mac"
	}
	
	for _, file := range files {
		if file.IsDir() || file.Name() == "README.md" || !isExecutable(filepath.Join(scriptsDir, file.Name())) {
			continue
		}
		
		// Create display name with directory prefix for clarity
		name := strings.TrimSuffix(file.Name(), filepath.Ext(file.Name()))
		dirName := filepath.Base(scriptsDir)
		if dirName == "examples" {
			name = PrefixExample + name
		} else if dirName == "user" {
			name = PrefixUser + name
		}
		
		scriptPath := "./" + filepath.Join(scriptsDir, file.Name())
		
		option := MenuOption{
			Display: name,
			Commands: map[string]string{
				"linux":   scriptPath,
				"mac":     scriptPath,
				"windows": scriptPath,
			},
		}
		discovered = append(discovered, option)
	}
	
	return discovered
}

func isExecutable(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return info.Mode()&0111 != 0 // Check if any execute bit is set
}

func mergeOptions(config []MenuOption, discovered []MenuOption) []MenuOption {
	// Create set of script paths already in config
	configPaths := make(map[string]bool)
	for _, option := range config {
		for _, cmd := range option.Commands {
			if strings.HasPrefix(cmd, "./" + ScriptsDirExamples) || strings.HasPrefix(cmd, "./" + ScriptsDirUser) || strings.HasPrefix(cmd, "./" + ScriptsDirLegacy) {
				configPaths[cmd] = true
			}
		}
	}
	
	// Add discovered scripts that aren't already in config
	merged := append([]MenuOption{}, config...)
	deduped := 0
	for _, option := range discovered {
		scriptPath := option.Commands["linux"] // All OS use same path
		if !configPaths[scriptPath] {
			merged = append(merged, option)
		} else {
			deduped++
		}
	}
	
	
	return merged
}

func commandExists(cmd string) bool {
	_, err := exec.LookPath(cmd)
	return err == nil
}

func executeCommand(command string) error {
	cmd := exec.Command(strings.Fields(ShellCommand)[0], strings.Fields(ShellCommand)[1], command)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// Old main function moved to runInteractiveMenu above

func showUsage() {
	fmt.Println(AppTitle)
	fmt.Println("")
	fmt.Println("Usage:")
	fmt.Println("  cmdy           Run interactive menu")
	fmt.Println("  cmdy build     Build the binary (requires source)")
	fmt.Println("  cmdy install   Install/update globally (requires source)")
	fmt.Println("  cmdy dev [msg] Commit, push, and install (dev workflow)")
	fmt.Println("  cmdy update    Update to latest version (works for all users)")
	fmt.Println("  cmdy version   Show current version")
	fmt.Println("  cmdy config    Edit config file")
	fmt.Println("  cmdy help      Show this help")
}

func buildCmdy() {
	// Check if Go is available
	if !commandExists("go") {
		fmt.Println("Error: Go compiler not found")
		fmt.Println("Install Go: https://golang.org/doc/install")
		os.Exit(1)
	}
	
	// Check if main.go exists
	if _, err := os.Stat("main.go"); err != nil {
		fmt.Printf("Error: main.go not found (%v)\n", err)
		os.Exit(1)
	}
	
	cmd := exec.Command("go", "build", "-ldflags=-s -w", "-o", "cmdy")
	cmd.Stdout = nil
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Build failed: %v\n", err)
		os.Exit(1)
	}
}

func installCmdy() {
	// Build first
	buildCmdy()
	
	// Verify binary was created
	if _, err := os.Stat(BinaryName); err != nil {
		fmt.Printf("Error: Binary not found after build (%v)\n", err)
		os.Exit(1)
	}
	
	// Determine install location
	installPath := GetInstallPath()
	tempPath := installPath + ".tmp"
	
	// Create directory if needed
	os.MkdirAll(filepath.Dir(installPath), 0755)
	
	// Copy binary to temp file first
	src, err := os.Open(BinaryName)
	if err != nil {
		fmt.Printf("Failed to open binary: %v\n", err)
		os.Exit(1)
	}
	defer src.Close()
	
	dst, err := os.Create(tempPath)
	if err != nil {
		fmt.Printf("Failed to create temp file: %v\n", err)
		os.Exit(1)
	}
	defer dst.Close()
	
	_, err = io.Copy(dst, src)
	if err != nil {
		fmt.Printf("Failed to copy binary: %v\n", err)
		os.Exit(1)
	}
	
	// Make executable
	os.Chmod(tempPath, PermExecutable)
	dst.Close() // Close before rename
	
	// Atomic rename (works even if target is in use)
	err = os.Rename(tempPath, installPath)
	if err != nil {
		fmt.Printf("Failed to install: %v\n", err)
		// Clean up temp file
		os.Remove(tempPath)
		os.Exit(1)
	}
}

func devWorkflow() {
	msg := DefaultCommitMsg
	if len(os.Args) > 2 {
		msg = strings.Join(os.Args[2:], " ")
	}
	
	// Run git commit and push script
	cmd := exec.Command("./git-commit-push.sh", msg, GitRemote, GitBranch)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("Development workflow failed: %v\n", err)
		os.Exit(1)
	}
	
	// Install after successful git workflow
	installCmdy()
	
	fmt.Println(SuccessComplete)
}

func updateCmdy() {
	// Show branding
	fmt.Println("\033[0;34m")
	fmt.Println("  ██████╗ ███╗   ███╗ ██████╗  ██╗   ██╗")
	fmt.Println(" ██╔════╝ ████╗ ████║ ██╔══██╗ ╚██╗ ██╔╝")
	fmt.Println(" ██║      ██╔████╔██║ ██║  ██║  ╚████╔╝ ")
	fmt.Println(" ██║      ██║╚██╔╝██║ ██║  ██║   ╚██╔╝  ")
	fmt.Println(" ╚██████╗ ██║ ╚═╝ ██║ ██████╔╝    ██║   ")
	fmt.Println("  ╚═════╝ ╚═╝     ╚═╝ ╚═════╝     ╚═╝   ")
	fmt.Println("\033[0m")
	fmt.Println("\033[0;34m🔄 Updating cmdy\033[0m")
	
	// Find the cmdy source directory
	sourceDir := findCmdySource()
	if sourceDir == "" {
		updateViaInstaller()
		return
	}
	
	// Change to source directory
	originalDir, _ := os.Getwd()
	defer os.Chdir(originalDir)
	os.Chdir(sourceDir)
	
	// Git pull
	cmd := exec.Command("git", "pull", "origin", "master")
	cmd.Stdout = nil
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Printf("\033[0;31m❌ Update failed: %v\033[0m\n", err)
		os.Exit(1)
	}
	
	// Check if config has changed and preserve user config
	preserveUserConfig()
	
	// Build and install
	installCmdy()
	
	fmt.Println("\033[0;32m✓ Updated\033[0m")
}

func updateViaInstaller() {
	// Show branding
	fmt.Println("\033[0;34m")
	fmt.Println("  ██████╗ ███╗   ███╗ ██████╗  ██╗   ██╗")
	fmt.Println(" ██╔════╝ ████╗ ████║ ██╔══██╗ ╚██╗ ██╔╝")
	fmt.Println(" ██║      ██╔████╔██║ ██║  ██║  ╚████╔╝ ")
	fmt.Println(" ██║      ██║╚██╔╝██║ ██║  ██║   ╚██╔╝  ")
	fmt.Println(" ╚██████╗ ██║ ╚═╝ ██║ ██████╔╝    ██║   ")
	fmt.Println("  ╚═════╝ ╚═╝     ╚═╝ ╚═════╝     ╚═╝   ")
	fmt.Println("\033[0m")
	fmt.Println("\033[0;34m🔄 Updating cmdy\033[0m")
	
	// Download and execute installer
	cmd := exec.Command("bash", "-c", "curl -sSL https://raw.githubusercontent.com/jdpierce21/cmdy/master/install.sh | bash")
	cmd.Stdout = nil
	cmd.Stderr = os.Stderr
	
	if err := cmd.Run(); err != nil {
		fmt.Printf("\033[0;31m❌ Update failed: %v\033[0m\n", err)
		os.Exit(1)
	}
	
	fmt.Println("\033[0;32m✓ Updated\033[0m")
}

func findCmdySource() string {
	// First check current directory
	if isGitRepo(".") && hasCmdyFiles(".") {
		dir, _ := os.Getwd()
		return dir
	}
	
	// Common locations to check
	homeDir, _ := os.UserHomeDir()
	locations := make([]string, len(SourceSearchLocations))
	for i, loc := range SourceSearchLocations {
		locations[i] = filepath.Join(homeDir, loc)
	}
	
	for _, location := range locations {
		if isGitRepo(location) && hasCmdyFiles(location) {
			return location
		}
	}
	
	return ""
}

func isGitRepo(dir string) bool {
	gitDir := filepath.Join(dir, ".git")
	_, err := os.Stat(gitDir)
	return err == nil
}

func hasCmdyFiles(dir string) bool {
	mainGo := filepath.Join(dir, "main.go")
	configYaml := filepath.Join(dir, "config.yaml")
	_, err1 := os.Stat(mainGo)
	_, err2 := os.Stat(configYaml)
	return err1 == nil && err2 == nil
}

func preserveUserConfig() {
	userConfigPath := GetConfigPath()
	newConfigPath := ConfigFileName
	
	// Check if user has a config and if it differs from new default
	if _, err := os.Stat(userConfigPath); err == nil {
		// User config exists, check if new config is different
		cmd := exec.Command("diff", "-q", userConfigPath, newConfigPath)
		if err := cmd.Run(); err != nil {
			// Configs differ, backup the new one
			backupPath := filepath.Join(ConfigDir, ConfigFileBackup)
			copyFile(newConfigPath, backupPath)
		}
	}
}

func copyFile(src, dst string) error {
	source, err := os.Open(src)
	if err != nil {
		return err
	}
	defer source.Close()
	
	dest, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer dest.Close()
	
	_, err = io.Copy(dest, source)
	return err
}

func showVersion() {
	cmd := exec.Command("git", "rev-parse", "--short", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		fmt.Println(VersionUnknown)
		return
	}
	fmt.Printf("cmdy version: %s\n", strings.TrimSpace(string(output)))
}

func editConfig() {
	configPath := ConfigFileName
	
	editor, err := findEditor()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		fmt.Println("")
		fmt.Println("Solutions:")
		fmt.Println("1. Set EDITOR environment variable: export EDITOR=vim")
		fmt.Println("2. Install a text editor: apt install nano")
		fmt.Println("3. Edit manually: nano config.yaml")
		return
	}
	
	fmt.Printf("Opening %s with %s...\n", configPath, editor)
	cmd := exec.Command(editor, configPath)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		fmt.Printf("Editor failed: %v\n", err)
	}
}

func findEditor() (string, error) {
	// Try environment variable first
	if editor := os.Getenv("EDITOR"); editor != "" {
		if commandExists(editor) {
			return editor, nil
		}
		fmt.Printf("Warning: EDITOR '%s' not found, trying fallbacks...\n", editor)
	}
	
	// Progressive fallback
	candidates := EditorCandidates
	for _, candidate := range candidates {
		if commandExists(candidate) {
			return candidate, nil
		}
	}
	
	return "", fmt.Errorf("no suitable text editor found")
}

func runInteractiveMenu() {
	
	data, err := os.ReadFile("config.yaml")
	if err != nil {
		fmt.Printf("Error: Cannot read config.yaml (%v)\n", err)
		fmt.Println("")
		fmt.Println("Solutions:")
		fmt.Println("1. Create config.yaml in current directory")
		fmt.Println("2. Run from cmdy source directory")
		fmt.Println("3. Reinstall: curl -sSL install.sh | bash")
		os.Exit(1)
	}

	var config struct {
		MenuOptions []MenuOption `yaml:"menu_options"`
	}
	if err := yaml.Unmarshal(data, &config); err != nil {
		fmt.Printf("Error: Invalid YAML in config.yaml (%v)\n", err)
		fmt.Println("Please check the file format and try again")
		os.Exit(1)
	}

	
	// Auto-discover scripts and merge with config
	discovered := discoverScripts()
	allOptions := mergeOptions(config.MenuOptions, discovered)
	
	if len(allOptions) == 0 {
		fmt.Println("Error: No menu options available")
		fmt.Println("")
		fmt.Println("Solutions:")
		fmt.Println("1. Add entries to config.yaml")
		fmt.Println("2. Add executable scripts to scripts/ directory")
		fmt.Println("3. Check example config: https://github.com/jdpierce21/cmdy")
		os.Exit(1)
	}
	

	currentOS := runtime.GOOS
	if currentOS == "darwin" {
		currentOS = "mac"
	}

	optionMap := make(map[string]*MenuOption, len(allOptions))
	for i := range allOptions {
		optionMap[allOptions[i].Display] = &allOptions[i]
	}

	for {
		selected, err := runFzf(allOptions)
		if err != nil || selected == "" {
			break
		}

		if option, exists := optionMap[selected]; exists {
			if command, hasCommand := option.Commands[currentOS]; hasCommand {
				if err := executeCommand(command); err != nil {
					fmt.Printf("Error: %v\n", err)
				}
			}
		}
	}
}

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "build":
			buildCmdy()
		case "install":
			installCmdy()
		case "dev":
			devWorkflow()
		case "update":
			updateCmdy()
		case "version":
			showVersion()
		case "config":
			editConfig()
		case "help", "--help", "-h":
			showUsage()
		default:
			fmt.Printf("Unknown command: %s\n\n", os.Args[1])
			showUsage()
			os.Exit(1)
		}
		return
	}
	
	// No arguments - run interactive menu
	runInteractiveMenu()
}

